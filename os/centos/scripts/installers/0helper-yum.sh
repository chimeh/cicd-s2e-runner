#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-cloud.sh
ls /etc/yum.repos.d
sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
sed -i 's/mirrorlist/#mirrorlist/' /etc/yum.repos.d/*.repo

egrep "baseurl" -r /etc/yum.repos.d |egrep -i -v vault

# Tencent Cloud
if runon_tencentcloud;then
  echo "Run on Tencent Cloud"
  sed -i 's|^#\?\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.tencentyun.com/centos/$releasever|g' /etc/yum.repos.d/*.repo
  yum install -y --nogpgcheck  epel-release
  sed -i 's|^#\?baseurl=https://download.fedoraproject.org/pub/epel|baseurl=http://mirrors.tencentyun.com/epel|g' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
  exit 0
fi
# Aliyun Cloud

if runon_aliyun;then
  echo "Run on Aliyun Cloud"
  sed -i 's|^#\?\(baseurl.*\)mirror.centos.org/centos/$releasever|baseurl=http://mirrors.cloud.aliyuncs.com/centos/$releasever|g' /etc/yum.repos.d/*.repo
  yum install -y --nogpgcheck  epel-release
  sed -i 's|^#\?\(baseurl.*\)download.fedoraproject.org/pub/epel|baseurl=https://mirrors.aliyun.com/epel|g' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
  exit 0
fi

# Huawei Cloud
if runon_huaweicloud;then
  echo "Run on Huawei Cloud"
  sed -i 's|^#\?\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.myhuaweicloud.com/centos/$releasever|g' /etc/yum.repos.d/*.repo
  yum install -y --nogpgcheck  epel-release
  sed -i 's|^#\?\(baseurl.*\)download.fedoraproject.org/pub/epel|\1mirrors.myhuaweicloud.com/epel|g' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
  exit 0
fi

if runon_cn;then
  true
  sed -i 's|^#\?\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirrors.tuna.tsinghua.edu.cn/centos/$releasever|g' /etc/yum.repos.d/*.repo
  yum install -y --nogpgcheck  epel-release
  sed -i 's|^#\?\(baseurl.*\)download.fedoraproject.org/pub/epel|\1mirrors.tuna.tsinghua.edu.cn/epel|g' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
else
  sed -i 's|^#\?\(baseurl.*\)mirror.centos.org/centos/$releasever|\1mirror.centos.org/centos/$releasever|g' /etc/yum.repos.d/*.repo
  yum install -y --nogpgcheck  epel-release
  sed -i 's|^#\?\(baseurl.*\)download.fedoraproject.org/pub/epel|\1mirrors.kernel.org/fedora-epel|g' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel*
fi
egrep "^baseurl" -r /etc/yum.repos.d |egrep -i -v vault
