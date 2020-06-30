#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/cloud.sh
ls /etc/yum.repos.d
sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
sed -i 's/mirrorlist/#mirrorlist/' /etc/yum.repos.d/*.repo
if runon_tencentcloud;then
  sed -i 's|#\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.cloud.tencent.com/centos/$releasever|' /etc/yum.repos.d/*.repo
fi


egrep "^baseurl" -r /etc/yum.repos.d

yum install -y --nogpgcheck  epel-release

# Tencent Cloud
if runon_tencentcloud;then
  sed -i 's|#\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.tencentyun.com/centos/$releasever|' /etc/yum.repos.d/*.repo
  sed -e 's|^metalink=|#metalink=|g' \
     -e 's|^#baseurl=https\?://download.fedoraproject.org/pub/epel/|baseurl=http://mirrors.tencentyun.com/epel/|g' \
     -i /etc/yum.repos.d/epel.repo
  exit 0
fi
# Aliyun Cloud

if runon_aliyun;then
  sed -i 's|#\baseurl=https\?://mirror.centos.org/centos/$releasever|baseurl=http://mirrors.cloud.aliyuncs.com/centos/$releasever|' /etc/yum.repos.d/*.repo
  sed -i 's|^#baseurl=https://download.fedoraproject.org/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
  exit 0
fi

