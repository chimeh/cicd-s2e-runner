#!/bin/bash
#@author jimin.huang@nx-engine.com

set -e
if [ -f /usr/share/zoneinfo/Asia/Shanghai ];then
  echo "tz set to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  export TZ="Asia/Shanghai"
else
  echo "warn: no tzdata"
fi

export 	JAVA_TOOL_OPTIONS=" -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap"

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

#/etc/init.d/kibana start
#/etc/init.d/elasticsearch start
#/usr/share/logstash/bin/logstash --path.settings /etc/logstash
exec nginx -g'daemon off;'