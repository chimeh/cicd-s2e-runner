#!/bin/sh
# inject config data into container
#@author jimin.huang@nx-engine.com

set -e

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

if [ -f /usr/share/zoneinfo/Asia/Shanghai ];then
  echo "tz set to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  export TZ="Asia/Shanghai"
else
  echo "warn: no tzdata"
fi

export 	JAVA_OPTS=" -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"

mkdir -p /cfg/
if [ -f /cfg/env.txt ]; then
    echo "/cfg/env.txt mounted"
    set -a # automatically export all variables
    . /cfg/env.txt
    set +a
    echo "import  $(wc -l /cfg/env.txt) env vars from /cfg/env.txt done"
else
    echo "/cfg/env.txt not found!"
fi
if [ -f ${SCRIPT_DIR}/initdata/init.sh ]; then
    echo "${SCRIPT_DIR}/initdata/init.sh"
    sh "${SCRIPT_DIR}/initdata/init.sh"
fi
if [ -z ${HOSTNAME} ];then
    HOSTNAME=no-name-service
fi

K8S_NS_FILE="/var/run/secrets/kubernetes.io/serviceaccount/namespace"
if [ -f ${K8S_NS_FILE} ];then
K8S_NS=`head -n 1 ${K8S_NS_FILE}`
else
K8S_NS="cant-get-ns"
fi
SVC_NAME=`echo ${K8S_NS}.${HOSTNAME} | rev | cut -d'-'  -f 3- | rev`
MY_K8S_NS=${K8S_NS}
MY_K8S_SVC_NAME=$(echo ${SVC_NAME} | awk -F. '{print $NF}')
echo "SVC_NAME=${SVC_NAME}"
echo "MY_K8S_NS=${MY_K8S_NS}"
echo "MY_K8S_SVC_NAME=${MY_K8S_SVC_NAME}"
export MY_K8S_NS
export MY_K8S_SVC_NAME


if [ ! -z "$(which java)" ];then
    JAVA_OPTS="${JAVA_OPTS} ${APM_OPTS} -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -XX:+UseG1GC -XX:G1ReservePercent=20 -Xloggc:/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=2M -XX:-PrintGCDetails -XX:+PrintGCDateStamps -XX:-PrintTenuringDistribution "
    
    jar=$(find / -maxdepth 1 -name "${MY_K8S_SVC_NAME}*jar" 2>/dev/null |egrep -v sources.jar |egrep -v tests.jar| sort | head -n 1)
    if [[ -z ${jar} ]];then
      jar=$(find /*.jar 2>/dev/null |egrep -v sources.jar |egrep -v tests.jar |head -n 1)
    fi
    echo "jar=${jar}"
    echo "JAVA_OPTS=${JAVA_OPTS}"
    if [ -n "${jar}" ];then
      echo "run ${jar}"
      exec java $JAVA_OPTS  -jar ${jar}
    else
      echo "cant detect jar, will exit"
      exit 1
    fi
fi
