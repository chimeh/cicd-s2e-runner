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

if [[ -n ${TEAMCITY_GIT_PATH} ]];then
    echo "Run on Teamcity"
    BUILD_COUNTER="t${BUILD_NUMBER}"
elif [[ -n ${JENKINS_URL} ]];then
    echo "Run on Jenkins CI"
    BUILD_COUNTER="j${BUILD_NUMBER}"
else
    echo "personal rc"
    BUILD_COUNTER="x"
fi


####################################################################

if [ $# -lt 1 ];then
  echo "useage: $0 namespace"
  exit 1;
fi
SRC_NS=$1
CURDATE=$(date +%Y%m%d%H%M%S)
VERSION=${CURDATE}-${BUILD_COUNTER}
echo "NS ${SRC_NS} ${VERSION}"

RCNAME=${TRYTOP}/../export-${SRC_NS}-${VERSION}
echo "${SRC_NS}-${CURDATE}"
echo "${RCNAME}"

kubectl cluster-info
kubectl get ns ${SRC_NS}
if [ $? -ne 0 ];then
  echo "NS ${SRC_NS} no exist"
  exit 2;
fi
mkdir -p ${RCNAME}

MWARE="redis|kafka|solr|elasticsearch|hbase|mongo|mysql|strimzi-cluster-operator|pvc|zookeeper"
echo "##########################gen img/ env/ port"
kubectl get -n ${SRC_NS} deployment  --no-headers |  awk '{print $1}' | egrep -v "${MWARE}" | \
while read i; do 
    name=$i
    echo "export app for ${SRC_NS}/${name}"
    mkdir -p ${RCNAME}/${name}
    img=`kubectl get -n ${SRC_NS} deployment $i  -o=jsonpath='{.spec.template.spec.containers[0].image}'`
    echo ${img} > ${RCNAME}/${name}/img.txt
    kubectl get -n ${SRC_NS} cm $name -o=jsonpath='{.data.env\.txt}' > ${RCNAME}/${name}/env.txt
    kubectl get -n ${SRC_NS} cm $name -o=jsonpath='{.data.default-entrypoint\.sh}' 2>/dev/null > ${RCNAME}/${name}/default-entrypoint.sh
    if [[ $(wc -l ${RCNAME}/${name}/default-entrypoint.sh  | awk '{print $1}') -lt 1 ]];then
      rm -f  ${RCNAME}/${name}/default-entrypoint.sh
    fi
    kubectl get -n ${SRC_NS} cm $name -o=jsonpath='{.data.override-entrypoint\.sh}' 2>/dev/null > ${RCNAME}/${name}/override-entrypoint.sh
    if [[ $(wc -l ${RCNAME}/${name}/override-entrypoint.sh  | awk '{print $1}') -lt 1 ]];then
      rm -f  ${RCNAME}/${name}/override-entrypoint.sh
    fi
    kubectl get -n ${SRC_NS} --export cm ${name}-initdata -o=yaml >${RCNAME}/${name}/${name}-initdata.yaml 2>/dev/null
    if [[ $(wc -l ${RCNAME}/${name}/${name}-initdata.yaml  | awk '{print $1}') -lt 1 ]];then
      rm -f  ${RCNAME}/${name}/${name}-initdata.yaml
    fi
done


