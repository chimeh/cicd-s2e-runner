#!/bin/sh
# inject config data into container
#@author jimin.huang@nx-engine.com

set -e
if [[ -f /usr/share/zoneinfo/Asia/Shanghai ]];then
  echo "tz set to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
else
  echo "warn: no tzdata"
fi

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

echo "detect NS ${K8S_NS} SVC ${SVC_NAME}"

echo -n '
#!/bin/sh
if [[ -f /cfg/env.txt ]];then  
    # first run
    if [[ ! -f /tmp/env.pre.md5 ]];then
        md5sum  /cfg/env.txt > /tmp/env.pre.md5
        exit 0
    else
        md5sum  /cfg/env.txt > /tmp/env.now.md5
        diff env.pre.md5 env.now.md5
        # cfg change
        ret=$?
        if [[ ${ret} -ne 0 ]];then
            exit 1
        fi
        /bin/cp -f /tmp/env.now.md5 /tmp/env.pre.md5
     fi
fi
' > /tmp/healthy.sh
chmod +x /tmp/healthy.sh

if [[ ! -z "$(which java)" ]];then
    PPAGENT=`find /pp-agent/pinpoint-bootstra* |head -n 1`
    if [[ -n "${PPAGENT}" && -n "${DISABLE_PINPOINT}" ]];then
      PINPOINT_OPTS="-javaagent:${PPAGENT} -Dpinpoint.agentId=${HOSTNAME:0:22} -Dpinpoint.applicationName=${SVC_NAME:0:22}"
    echo "enabled pinpoint apm"
    fi
    JAVA_OPTS="${JAVA_OPTS} ${PINPOINT_OPTS} -XX:+UseG1GC -XX:G1ReservePercent=20 -Xloggc:/gc.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=2M -XX:-PrintGCDetails -XX:+PrintGCDateStamps -XX:-PrintTenuringDistribution "
    
    echo 'JAVA_OPTS, you can RESET its value, use JAVA_OPTS="YOU-NEW-VALUE" in /cfg/env.txt"'
    echo 'JAVA_OPTS, you can APPEND its value, use JAVA_OPTS="${JAVA_OPTS} YOU-APPEND-VALUE" in /cfg/env.txt" '
    jar=$(find /*.jar 2>/dev/null |head -n 1)
    echo "jar=${jar}"
    echo "JAVA_OPTS=${JAVA_OPTS}"
    if [[ -n "${jar}" ]];then
      echo "run ${jar}"
      exec java $JAVA_OPTS  -jar ${jar}
    else
      echo "cant detect /app.jar, will exit"
      sleep 20; 
      exit 1
    fi
fi
