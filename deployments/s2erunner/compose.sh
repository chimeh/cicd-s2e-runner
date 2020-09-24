#!/bin/bash
set -e
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
COMPOSE_DIR=${SCRIPT_DIR}
COMPOSE_FACTORY_DIR="${SCRIPT_DIR}/.tpl"

CFGMAP_CMD=${COMPOSE_FACTORY_DIR}/cfgmap-cmd.sh
CFG_VOL=${COMPOSE_FACTORY_DIR}/cfgmap-mount.yaml
CFGMAP_LOG=${COMPOSE_FACTORY_DIR}/cfgmap-log.md
DOCKER_IMG=${COMPOSE_FACTORY_DIR}
mkdir -p ${COMPOSE_FACTORY_DIR}

function do-record-cmd () {
    touch ${CFGMAP_CMD}
    if [[ -s ${CFGMAP_CMD} ]];then
      echo $@ >> ${CFGMAP_CMD}
    else
      echo "#!/bin/bash" >${CFGMAP_CMD}
    fi
}

function do-volumes-map () {
    touch ${CFG_VOL}
    if [[ $# -gt 2 ]];then
      # great then 2 arg， assume fail
      echo "      #- ./$1:$2" >> ${CFG_VOL}
    else
      echo "      - ./$1:$2" >> ${CFG_VOL}
    fi
}

function do-cfgmapping {
  src="${COMPOSE_DIR}/$1"
  dst="$2"
  ok=0
  if [[ -f $src ]];then
    do-record-cmd mkdir -p $(dirname $dst)
    do-record-cmd /bin/cp -f $src $dst
    ok=1
  elif [[ -d $src ]];then
    do-record-cmd mkdir -p $dst
    do-record-cmd "#$1"
    for i in $(ls ${src});do
      do-record-cmd /bin/cp -rf  ${src}/$i $dst;
    done
    ok=1
  else
    ok=0
  fi
  #document it
  touch ${CFGMAP_LOG}
  if [[ ! -s ${CFGMAP_LOG} ]];then
    echo # Docker-compose secrets mapping
    echo "| docker-compose secretes  | container path |" >${CFGMAP_LOG}
    echo "| ------------- | ------------- |">>${CFGMAP_LOG}
  fi
  if [[ $ok -gt 0 ]];then
    echo "| $1  | $2 |" >>${CFGMAP_LOG}
    do-volumes-map $1 $2
  else
    echo "| [copy failed] \`$1\` | $2 |" >>${CFGMAP_LOG}
    do-volumes-map $1 $2 failed
  fi
}



function compose-gen()
{
  set -e
  cd ${COMPOSE_DIR}
  set +e
  truncate -s 0 ${CFGMAP_CMD} 2>/dev/null
  truncate -s 0 ${CFG_VOL} 2>/dev/null
  truncate -s 0 ${CFGMAP_LOG} 2>/dev/null
  set -e
  do-cfgmapping runner/secrets/gitlab-runner/config.toml     /etc/gitlab-runner/config.toml
  do-cfgmapping runner/secrets/profile.d/env.sh              /etc/profile.d/env.sh
  do-cfgmapping runner/secrets/maven/settings.xml            /root/.m2/settings.xml
  do-cfgmapping runner/secrets/docker                        /root/.docker
  do-cfgmapping runner/secrets/k8s/                          /root/.kube
  do-cfgmapping runner/secrets/email/mail.rc                  /etc/mail.rc
  do-cfgmapping runner/secrets/jira/acli.properties           /root/.jira/acli.properties
  do-cfgmapping runner/secrets/rancher/cli2.json              /root/.rancher/cli2.json
  do-cfgmapping runner/secrets/s2ectl/config.yaml             /root/.s2ectl/config.yaml
  do-cfgmapping runner/secrets/filebeat/filebeat.yml          /etc/filebeat/filebeat.yml
#  do-cfgmapping metricd/secrets/elasticsearch/elasticsearch.yml      /etc/elasticsearch/elasticsearch.yml
#  do-cfgmapping metricd/secrets/kibana/kibana.yml                    /etc/kibana/kibana.yml
#  do-cfgmapping metricd/secrets/logstash                             /etc/logstash
#  do-cfgmapping metricd/secrets/nginx/default.conf                   /etc/nginx/default.d/
  /bin/cp -f ${COMPOSE_DIR}/tpl/docker-compose.template.yaml ${COMPOSE_FACTORY_DIR}/docker-compose.yaml
  if  [[ -n ${DOCKER_IMG} ]];then
    perl -ni -e "s@^([# ]+image:).+@\1 ${IMG}@g;print" ${COMPOSE_FACTORY_DIR}/docker-compose.yaml
  fi
  cat ${CFG_VOL} >> ${COMPOSE_FACTORY_DIR}/docker-compose.yaml
}

compose-gen
