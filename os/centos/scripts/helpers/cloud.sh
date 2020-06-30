#!/bin/bash
################################################################################
##  File:  cloud.sh
##  Desc:  auto detect run on which cloud
################################################################################

# detect cloudinit
fuction runon_tencentcloud(){
  set +e
  scurl --connect-timeout 1 http://metadata.tencentyun.com/latest/meta-data/instance-id >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    return true
  else
    return false
  fi
}

fuction runon_aliyun(){
  set +e
  scurl --connect-timeout 1 curl http://100.100.100.200 >/dev/null 2>&1
  rv=$?
  set -e
  if [[ ${rv} -eq 0 ]];then
    return true
  else
    return false
  fi
}