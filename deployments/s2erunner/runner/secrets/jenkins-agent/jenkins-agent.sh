#!/bin/bash
#cicd toolset
#author: jimin.huang
#email: jimin.huang@benload.com
#email: jimminh@163.com
set -e
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

AGENT_JAR="${SCRIPT_DIR}/agent.jar"
AGENT_JAVA_OPTIONS_FILE="${SCRIPT_DIR}/jenkins_agent_java_options"
SECRET_FILE=${SCRIPT_DIR}/secret-file

if [[ ! -s ${SECRET_FILE} ]] ;then
    echo "can't find secret,please token into ${SECRET_FILE}.  eg. echo 6573cce17ae39b92b9500c > secret-file"
    exit 1
fi
if [[ ! -s ${AGENT_JAVA_OPTIONS_FILE} ]] ;then
    echo "you must define AGENT_JAVA_OPTIONS in ${AGENT_JAVA_OPTIONS_FILE}"
    exit 1
fi
. ${AGENT_JAVA_OPTIONS_FILE}

if [[ -z ${AGENT_JAVA_OPTIONS} ]];then
    echo "you must define AGENT_JAVA_OPTIONS in ${AGENT_JAVA_OPTIONS_FILE}"
fi

JENKINS_SERVER_HOST=$(echo ${AGENT_JAVA_OPTIONS} | perl -ni -e 'm|-jnlpUrl\s+https://([^/]+)/.+|;print $1;')

if [[ ! -f ${AGENT_JAR} ]];then
    echo "not found agent on ${AGENT_JAR}, try downloading from ${AGENT_JAR}"
    wget  --no-check-certificate -O ${AGENT_JAR} https://${JENKINS_SERVER_HOST}/jnlpJars/agent.jar
    rv=$?
    if [[ ${rv} -ne 0 ]];then
        "please download agent jar save as ${AGENT_JAR}!"
    fi
fi

CMD=(java -jar ${AGENT_JAR} -secret @${SECRET_FILE} ${AGENT_JAVA_OPTIONS} -workDir '/home/jenkins-agent')
echo -e "\n\n"
echo "run cmd:  ${CMD[*]}"
echo -e "\n\n"

exec ${CMD[*]}