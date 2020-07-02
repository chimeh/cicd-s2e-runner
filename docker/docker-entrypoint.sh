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

#nginx
if [ -f /home/github-runner/bin/runsvc.sh ]; then
  set +e;
   . /home/github-runner/bin/runsvc.sh start
  set -e
fi
RUNNER_TYPE="gitlab-runner"
if [ $# -gt 0 ];then
RUNNER_TYPE=$1
fi

echo "start ${RUNNER_TYPE}"
case ${RUNNER_TYPE} in
    gitlab-runner)
        exec gitlab-runner run  --user=root --working-directory=/home/gitlab-runner
        ;;
    github-runner)
        exec /home/github-runner/bin/runsvc.sh start
        ;;
    jenkins-slave)
        echo "not implement!"
        exit 1
        ;;
    webssh)
        echo "not implement!"
        exit 1
        ;;
    *)
        echo "unkown ${RUNNER_TYPE}"
        echo "current support runner: gitlab-runner github-runner"
        echo "support runner on futrue: jenkins-slave webssh"
        ;;
