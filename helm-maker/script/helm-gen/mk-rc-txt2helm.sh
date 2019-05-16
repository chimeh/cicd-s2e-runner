#!/bin/bash
#author huangjimin
#jimin.huang@nx-engine.com
#convert txtdir to helm 
USAGE="usage: $0  txtdir [NEWNAME] [VERSION]"

###################################################################
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
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

if [[ -n ${TEAMCITY_GIT_PATH} ]];then
    echo "Run on Teamcity"
    BUILD_COUNTER="-t${BUILD_NUMBER}"
elif [[ -n ${JENKINS_URL} ]];then
    echo "Run on Jenkins CI"
    BUILD_COUNTER="-j${BUILD_NUMBER}"
else
    echo "personal rc"
    BUILD_COUNTER=""
fi

####################################################################
CURDATE=$(date +%Y%m%d%H%M%S)
if [ $# -lt 1 ];then
  echo ${USAGE}
  exit 1;
fi
VERSION=${CURDATE}${BUILD_COUNTER}
if [ $# -gt 2 ];then                                                                                                   
  VERSION=$3
fi  
if [ $# -ge 2 ];then
#  CATALOG_NAME=$(echo $2 | tr '[A-Z]' '[a-z]' |tr -csd  "[0-9._-][a-z][A-Z]" "")
  CATALOG_NAME=$(echo $2 | tr '[A-Z]' '[a-z]')
else
#  CATALOG_NAME=$(echo $(basename $1) | tr '[A-Z]' '[a-z]' |tr -csd  "[0-9._][a-z][A-Z]" "")
  CATALOG_NAME=$(echo $(basename $1) | tr '[A-Z]' '[a-z]' )-${VERSION}
fi




TXTDIR=$(realpath ${1})
RCNAME=${PWD}/${CATALOG_NAME}
vaule_filename=values-release-txt2helm.yaml
commonchartversion=1.0

echo "CATALOG_NAME=${CATALOG_NAME}"
echo "VERSION=${VERSION}"
echo "RCNAME=${RCNAME}"


mkdir -p ${RCNAME}/charts
cat >> ${RCNAME}/Chart.yaml <<EOF
name: ${CATALOG_NAME}
version: ${VERSION}
appVersion: 0.1
description: gen helm from  $(basename $1) ${VERSION}
keywords:
- $(basename $1)
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
echo  'dependencies:' > ${RCNAME}/requirements.yaml
for i in `/bin/ls ${TXTDIR}`;do \
    name=$i
    echo "gen charts for /${name}"
    img=`head -n 1 ${TXTDIR}/${name}/img.txt`
    /bin/cp -rf  ${TRYTOP}/generic/xxx-generic-chart ${RCNAME}/charts/$name
    if [[ -f ${TXTDIR}/${name}/env.txt ]];then
       echo ${TXTDIR}/${name}/env.txt
        perl -ne "print ' ' x 0;print '';print \$_" ${TXTDIR}/${name}/env.txt >> ${RCNAME}/charts/$name/files/env.txt
    fi
    if [[ -f ${TXTDIR}/${name}/override-entrypoint.sh ]];then
       echo ${TXTDIR}/${name}/override-entrypoint.sh
        perl -ne "print ' ' x 0;print '';print \$_" ${TXTDIR}/${name}/override-entrypoint.sh >> ${RCNAME}/charts/$name/files/override-entrypoint.sh
    fi
    if [[ -d ${TXTDIR}/${name}/initdata ]];then
       /bin/cp -rf  ${TXTDIR}/${name}/initdata ${RCNAME}/charts/$name/files/
    fi
    if [[ ${name} == "ne-config-server" ]];then
       echo ${TXTDIR}/${name}/env.txt
       echo "" >> ${RCNAME}/charts/$name/files/initdata/xxx-service1.yaml
       echo "" >> ${RCNAME}/charts/$name/files/initdata/xxx-service2.yaml
    fi
    perl -ni -e "s/^name:.+/name: ${name}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^version:.+/version: ${commonchartversion}/g;print" ${RCNAME}/charts/$name/Chart.yaml
    perl -ni -e "s/^icev3-xxx-generic/$name/g;print" ${RCNAME}/charts/$name/values-single.yaml
    perl -ni -e "s@image:.+@image: $img@g;print"  ${RCNAME}/charts/$name/values-single.yaml
    echo "dependcies"
cat >> ${RCNAME}/requirements.yaml <<EOF
- name: ${name}
  version: ~${commonchartversion}
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
      domain: nxengine.cn
  containers:
    securityContext:
      privileged: true
EOF


for i in `/bin/ls ${TXTDIR}`;do \
    name=$i
    echo "gen charts for /${name}"
    img=`head -n 1 ${TXTDIR}/${name}/img.txt`
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
    image: $img
    service:
      type: ClusterIP
EOF
if [[ ${name} == "ev-gb-gateway" ]];then
cat >> ${RCNAME}/${vaule_filename} <<EOF
      ports:
        - 8111
        - 8080
EOF
elif [[ ${name} == "simu-ve" ]];then
cat >> ${RCNAME}/${vaule_filename} <<EOF
      ports:
        - 8080
        - 5000
EOF
elif [[ -f ${TXTDIR}/${name}/ports.txt ]];then
cat >> ${RCNAME}/${vaule_filename} <<EOF
      ports:
EOF
perl -n  -e 'my $pl=$_;my @ports= split /\,/, $pl; foreach(@ports) { print " " x 8;print  " - $_\n"}' ${TXTDIR}/${name}/ports.txt  >> ${RCNAME}/${vaule_filename} 
else
cat >> ${RCNAME}/${vaule_filename} <<EOF
      ports:
        - 8080
EOF
fi
cat >> ${RCNAME}/${vaule_filename} <<EOF
    env.txt: |
EOF
if [[ -f ${TXTDIR}/${name}/env.txt ]];then
   echo ${TXTDIR}/${name}/env.txt
    perl -ne "chomp(\$_);print ' ' x 6;print \$_;print qq(\n);" ${TXTDIR}/${name}/env.txt >> ${RCNAME}/${vaule_filename}
fi
done

echo "##############################################################"


cat ${RCNAME}/${vaule_filename} > ${RCNAME}/values.yaml

################# post to repo
#http://charts.ops/api/charts
if [ $# -gt 3 ];then
  echo "post to repo"
  rm -rf ${RCNAME}/../${CATALOG_NAME}
  /bin/cp -rf ${RCNAME} ${RCNAME}/../${CATALOG_NAME}
  cd ${RCNAME}/..
  helm package ${CATALOG_NAME}
  rm -rf ${RCNAME}/../${CATALOG_NAME}
  curl --data-binary "@${CATALOG_NAME}-${VERSION}.tgz" https://helm-charts.nx-engine.com/api/charts
  curl --data-binary "@${CATALOG_NAME}-${VERSION}.tgz" $3

fi
