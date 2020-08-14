#!/bin/bash
#@author jimin.huang@benload.com

set -e
if [ -f /usr/share/zoneinfo/Asia/Shanghai ];then
  echo "tz set to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  export TZ="Asia/Shanghai"
else
  echo "warn: no tzdata"
fi

#export 	JAVA_TOOL_OPTIONS=" -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"

mkdir -p /etc/profile.d/
if [ -f /etc/profile.d/env.sh ]; then
    echo "/cfg/env.txt mounted"
    set -a # automatically export all variables
    . /etc/profile.d/env.sh
    set +a
    echo "import env vars from /etc/profile.d/env.sh done"
else
    echo "/etc/profile.d/env.sh not found!"
fi


RUNNER_TYPE="gitlab-runner"
if [ $# -gt 0 ];then
RUNNER_TYPE=$1
elif ! command -v gitlab-runner;then
  RUNNER_TYPE="tailf"
fi
echo "support : gitlab-runner action-runner tailf"
echo "start ${RUNNER_TYPE}"
case ${RUNNER_TYPE} in
    default)
        mkdir -p /home/gitlab-runner
        mkdir -p /home/action-runner
        exec supervisord --nodaemon --configuration /docker/supervisord.conf
        ;;
    gitlab-runner)
        mkdir -p /home/gitlab-runner
        exec gitlab-runner run  --user=root --working-directory=/home/gitlab-runner
        ;;
    action-runner)
        mkdir -p /home/action-runner
        exec /home/action-runner/bin/run.sh
        ;;
    jenkins-slave)
        echo "not implement!"
        exit 1
        ;;
    webssh)
        echo "not implement!"
        exit 1
        ;;
    metricbeat)
        /etc/init.d/filebeat start
        exec tail -f /dev/null
        ;;
    metricd)
        /etc/init.d/kibana start
        /etc/init.d/elasticsearch start
        exec /usr/share/logstash/bin/logstash --path.settings /etc/logstash
        ;;
    tailf)
        exec tail -f /dev/null
        ;;
    *)
        echo "unkown ${RUNNER_TYPE}"
        exec tail -f /dev/null
        ;;
esac
