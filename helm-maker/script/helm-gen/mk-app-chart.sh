#!/bin/bash
#author huangjimin
#jimin.huang@nx-engine.com
#convert txtdir to helm 
USAGE="usage: $0  IMG SVCNAME K8S_NS [PORTS: 80,8080,...] [AUTODEPLOY:0|1] [DOMAIN_INTERNAL] [DOMAIN_PUBLIC]
       usage: $0 docker.io/nginx:latest nginx  default 80,8080  1 dev-k8s.tx e-engine.cn"
echo "${USAGE}"
###################################################################
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
TRYTOP=$(xdir=${SCRIPT_DIR};cd ${SCRIPT_DIR}; while /usr/bin/test ! -e .TOP ; do \
        xdir=`cd ../;pwd`;                       \
        if [ "$xdir" = "/" ] ; then             \
           echo  1>&2; \
           break;                              \
        fi ;                                    \
        cd $xdir;                               \
        done ;                                  \
        pwd;)

WORKDIR=$(pwd)
if [[ -z ${TRYTOP} ]];then
TRYTOP=${WORKDIR}
fi
if [[ $# -gt 5 ]];then
    DOMAIN_INTERNAL=$6
fi
if [[ $# -gt 6 ]];then
    DOMAIN_PUBLIC=$7
fi
if [[ -z ${DOMAIN_INTERNAL} ]];then
    DOMAIN_INTERNAL=okd.cd
fi
if [[ -z ${DOMAIN_PUBLIC} ]];then
    DOMAIN_PUBLIC=e-engine.cn
fi

####################################################################
CURDATE=$(date +%Y%m%d)
if [ $# -lt 3 ];then
  echo "${USAGE}"
  exit 1;
fi
IMG=$1
SVCNAME=$2
K8S_NS=$3
if [[ $# -gt 3 ]];then
    PORTS=$4
else
    PORTS=8080
fi
if [[ $# -gt 4 ]];then
    AUTODEPLOY=1
else
    AUTODEPLOY=0
fi

CATALOG_NAME=$(echo ${SVCNAME} | tr '[A-Z]' '[a-z]')
VERSION=${CURDATE}${BUILD_COUNTER}
APPNAME=$(realpath ${WORKDIR}/${SVCNAME})
VAULE_FILENAME=values-${SVCNAME}.yaml
COMMONCHARTVERSION=1.0
echo "IMG=${IMG}"
echo "SVCNAME=${SVCNAME}"
echo "K8S_NS=${K8S_NS}"
echo "AUTODEPLOY=${AUTODEPLOY}"
echo "CATALOG_NAME=${CATALOG_NAME}"
echo "VERSION=${VERSION}"
echo "APPNAME=${APPNAME}"
echo "VAULE_FILENAME=${VAULE_FILENAME}"
echo "COMMONCHARTVERSION=${COMMONCHARTVERSION}"
echo "THIS_SCRIPT=${THIS_SCRIPT}"
echo "SCRIPT_DIR=${SCRIPT_DIR}"
echo "WORKDIR=${WORKDIR}"
echo "TRYTOP=${TRYTOP}"
echo "DOMAIN_INTERNAL=${DOMAIN_INTERNAL}"
echo "DOMAIN_PUBLIC=${DOMAIN_PUBLIC}"
echo "KUBECONFIG=${KUBECONFIG}"

if [[ -n ${TEAMCITY_GIT_PATH} ]];then
    echo "Run on Teamcity"
    BUILD_COUNTER="-t${BUILD_NUMBER}"
elif [[ -n ${JENKINS_URL} ]];then
    echo "Run on Jenkins CI"
    BUILD_COUNTER="-j${BUILD_NUMBER}"
elif [[ -n ${GITLAB_CI} ]];then
    echo "Run on Gitlab CI"
    BUILD_COUNTER="-g${BUILD_NUMBER}"
else
    echo "personal rc"
    BUILD_COUNTER=""
fi



mkdir -p ${APPNAME}/charts
cat >> ${APPNAME}/Chart.yaml <<EOF
name: ${CATALOG_NAME}
version: ${VERSION}
appVersion: 1.0
description: gen helm for ${APPNAME}
keywords:
- ${SVCNAME}
home: https://www.nx-engine.com/
icon: https://www.nx-engine.com/img/36577051900299436.png
sources:
- https://www.nx-engine.com/
maintainers:
- name: Jimmy Huang
  email: jimagile@gmail.com
engine: gotpl
EOF

echo "##########################gen charts, and depencies"
echo  'dependencies:' > ${APPNAME}/requirements.yaml
for i in ${SVCNAME};do \
    name=$i
    echo "gen charts for ${name}"
    img=${IMG}
    /bin/cp -rf  ${TRYTOP}/generic/xxx-generic-chart ${APPNAME}/charts/$name
    if [[ -n ${K8S_NS} ]];then
       echo "get env.txt from ${K8S_NS} "
       touch ${APPNAME}/charts/${name}/env.txt.old
       kubectl get -n ${K8S_NS} cm $name -o=jsonpath='{.data.env\.txt}' > ${APPNAME}/charts/${name}/env.txt.old
       perl -ne "chomp(\$_);print ' ' x 0;print \$_;print qq(\n);" ${APPNAME}/charts/${name}/env.txt.old >> ${APPNAME}/charts/$name/files/env.txt
       rm -f ${APPNAME}/${name}/env.txt.old
    fi
    perl -ni -e "s/^name:.+/name: ${name}/g;print" ${APPNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^version:.+/version: ${COMMONCHARTVERSION}/g;print" ${APPNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^icev3-xxx-generic/$name/g;print" ${APPNAME}/charts/$name/values-single.yaml
    perl -ni -e "s@image:.+@image: ${IMG}@g;print"  ${APPNAME}/charts/$name/values-single.yaml
    echo "dependcies"
cat >> ${APPNAME}/requirements.yaml <<EOF
- name: ${name}
  version: ~${COMMONCHARTVERSION}
  repository: "file://charts/${name}"
EOF
done

echo "##########################gen value file"
cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
global:
  rc-fullname: false
  ingress:
    internal:
      annotations-ingress-class: kong-ingress-internal
      domain: ${DOMAIN_INTERNAL}
    public:
      annotations-ingress-class: kong-ingress-public
      domain: ${DOMAIN_PUBLIC}
  containers:
    securityContext:
      privileged: true
EOF


for i in ${SVCNAME};do \
    name=$i
    echo "gen charts for ${name}"
    img=${IMG}
cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
${name}:
  ${name}:
    replicaCount: 1
    ingress:
      internal: 
        host: {}
      public: 
        enabled: true
        host: {}
    image: ${IMG}
    service:
      type: ClusterIP
EOF
if [[ ${name} == "ev-gb-gateway" ]];then
cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
      ports:
        - 8111
        - 8080
EOF
elif [[ ${name} == "simu-ve" ]];then
cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
      ports:
        - 8080
        - 5000
EOF
else
cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
      ports:
EOF

echo -n ${PORTS} | perl -ni  -e 'my $pl=$_;my @ports= split /\,/, $pl; foreach(@ports) { print " " x 8;print  " - $_\n"}'  >> ${APPNAME}/${VAULE_FILENAME}
fi

cat >> ${APPNAME}/${VAULE_FILENAME} <<EOF
    env.txt: |
EOF

done
/bin/cp -f ${APPNAME}/${VAULE_FILENAME}  ${APPNAME}/values.yaml
echo "###########################################helm chart gen done"
if [[ ${AUTODEPLOY} -gt 0 ]];then
   echo "###########################################auto deploy"
   helm upgrade  --install  --namespace ${K8S_NS} ${SVCNAME} ${APPNAME}
fi

