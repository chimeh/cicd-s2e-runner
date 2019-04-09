#!/bin/bash
#author huangjimin
#jimin.huang@nx-engine.com
#get info from k8s namespace, then generate helm template for all services in the NS

###################################################################
THIS_SCRIPT=$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0})
#automatic detection TOPDIR
CUR_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
TRYTOP=$(xdir=${CUR_DIR};cd ${CUR_DIR}; while /usr/bin/test ! -e .TOP ; do \
        xdir=`cd ../;pwd`;                       \
        if [ "$xdir" = "/" ] ; then             \
           echo  1>&2; \
           break;                              \
        fi ;                                    \
        cd $xdir;                               \
        done ;                                  \
        pwd;)

if [[ -z ${TRYTOP} ]];then
TRYTOP=${CUR_DIR}
fi
echo THIS_SCRIPT=$THIS_SCRIPT
echo CUR_DIR=$CUR_DIR
echo TRYTOP=$TRYTOP


####################################################################
if [ $# -lt 1 ];then
  echo "useage: $0 namespace"
  exit 1;
fi
projname=release-$1
CURDATE=$(date +%Y%m%d-%H-%M-%S)
RCNAME=${TRYTOP}/../${projname}-${CURDATE}
vaule_filename=values-release-apps.yaml
requirement_filename=requirements.yaml
defaultversion=${CURDATE}
echo "${projname}-${CURDATE}"

kubectl cluster-info
SRC_NS=$1
kubectl get ns ${SRC_NS}
if [ $? -ne 0 ];then
  echo "NS ${SRC_NS} no exist"
  exit 2;
fi
mkdir -p ${RCNAME}/charts
cat >> ${RCNAME}/Chart.yaml <<EOF
name: ${projname}
version: ${CURDATE}
appVersion: 0.1
description: all icev3-dependcies
keywords:
- nextengine
- icev3-dependcies
home: https://www.nx-engine.com/
icon: https://bitnami.com/assets/stacks/postgresql/img/postgresql-stack-110x117.png
sources:
- https://www.nx-engine.com/
maintainers:
- name: Jimmy Huang
  email: jimagile@gmail.com
engine: gotpl
EOF
MWARE="redis|kafka|solr|elasticsearch|hbase|mongo|mysql|strimzi-cluster-operator|pvc|zookeeper"

echo "##########################gen charts, and depencies"
echo  'dependencies:' > ${RCNAME}/requirements.yaml
for i in `/bin/ls ice-bus-dev` ; do 
    name=$i
    echo "auto gen charts for ${SRC_NS}/${name}"
    img="harbor-chengdu.nx-engine.com/ice/ne-evgb-dashboard:1.0.2-afe185d"
    /bin/cp -rf  ${TRYTOP}/generic/xxx-generic-chart ${RCNAME}/charts/$name
    echo '' >${RCNAME}/charts/$name/files/env.txt
    perl -ni -e "s/^name:.+/name: ${name}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^version:.+/version: ${defaultversion}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^icev3-xxx-generic/$name/g;print" ${RCNAME}/charts/$name/values-single.yaml
    perl -ni -e "s@image:.+@image: $img@g;print"  ${RCNAME}/charts/$name/values-single.yaml
    echo "dependcies"
cat >> ${RCNAME}/requirements.yaml <<EOF
- name: ${name}
  version: ~${defaultversion}
  repository: "file://charts/${name}"
EOF
done

echo "##########################gen value file"
cat >> ${RCNAME}/${vaule_filename} <<EOF
global:
  rc-fullname: false
  ingress:
    internal:
      annotations-ingress-class: kong-ingress-internal
      domain: okd.cd
    public:
      annotations-ingress-class: kong-ingress-public
      domain: nx-ice.com
EOF

MWARE="redis|kafka|solr|elasticsearch|hbase|mongo|mysql|strimzi-cluster-operator|pvc|zookeeper"

for i in `/bin/ls ice-bus-dev` ; do 
    name=$i
    img=nginx
cat >> ${RCNAME}/${vaule_filename} <<EOF
${name}:
  ${name}:
    replicaCount: 1
    ingress:
      internal: 
        host: {}
      public: 
        enabled: true
        host: {}
    service:
      type: ClusterIP
      ports:
        - 80
        - 8080
    image: $img
    env.txt: |
      #from ${vaule_filename}
EOF
done

echo "##############################################################"
echo "##########################gen middleware charts, and depencies"
MWDIR=${RCNAME}/charts/infra-middleware/charts
MW_VALUEFILE=${RCNAME}/values-middleware-all-in-one.yaml

mkdir -p ${MWDIR}
/bin/cp -rf  ${TRYTOP}/infra-middleware/* ${MWDIR}

cat  >>  ${MW_VALUEFILE} <<EOF
infra-middleware:
EOF
#################merge mw chart into one
echo  'dependencies:' > $(dirname ${MWDIR})/requirements.yaml
for i in `/bin/ls ${MWDIR} `; do 
    name=$i
    echo "auto gen charts for middleware ${name}"
    version=$( cat ${MWDIR}/${name}/Chart.yaml   |egrep "^version" | perl -ne 'print $1 if /^version:[ ]+(.+)/')
    mv ${MWDIR}/${name}/values.yaml ${MWDIR}/${name}/values-single.yaml

echo " let infra-middleware depend ${name}"
cat >> $(dirname ${MWDIR})/requirements.yaml <<EOF
- name: ${name}
  version: ~${version}
  repository: "file://charts/${name}"
  condition: ${name}.enabled
EOF
echo " merge ${name} valuefile"
cat  >>  ${MW_VALUEFILE} <<EOF
  ${name}:
    enabled: false
EOF
perl  -ne 'print "    $_"' ${MWDIR}/${name}/values-single.yaml  >>  ${MW_VALUEFILE}
done 



##################let mw below top chart
echo "name: infra-middleware" > $(dirname ${MWDIR})/Chart.yaml
echo "version: 0.9.1" >> $(dirname ${MWDIR})/Chart.yaml

cat >> ${RCNAME}/requirements.yaml <<EOF
- name: infra-middleware
  version: ~0.9.1
  repository: "file://charts/infra-middleware"
EOF
cat ${RCNAME}/${vaule_filename} > ${RCNAME}/values.yaml
cat ${MW_VALUEFILE} >> ${RCNAME}/values.yaml

################# post to repo
if [ $# -gt 1 ];then
  echo "post to repo"
  rm -rf ${RCNAME}/../${projname}
  /bin/cp -rf ${RCNAME} ${RCNAME}/../${projname}
  cd ${RCNAME}/..
  helm package ${projname}
  curl --data-binary "@${projname}-${CURDATE}.tgz" http://charts.ops/api/charts
fi
