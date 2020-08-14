#!/bin/bash
################################################################################
##  File:  cloud.sh
##  Desc:  auto detect run on which cloud
################################################################################

if ! command -v scurl; then
  if  command -v curl; then
    ln -s $(which curl) /usr/local/bin/scurl
  fi
fi > /dev/null

# detect cloudinit
function runon_tencentcloud()
{
  set +e
  #egrep -iq tencent /etc/ntp.conf
  scurl --connect-timeout 1 http://metadata.tencentyun.com/latest/meta-data/instance-id >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    true 
  else
    false
  fi
}

function runon_aliyun ()
{
  set +e
  scurl --connect-timeout 1 http://100.100.100.200 >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    true
  else
    false
  fi
}

function runon_huaweicloud ()
{
  set +e
  scurl --connect-timeout 1 http://mirrors.myhuaweicloud.com >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    true
  else
    false
  fi
}

function runon_cn ()
{
  set +e
  scurl --connect-timeout 1  http://www.google.com >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    false # runon_cn can't visit google
  else
    true
  fi
}
