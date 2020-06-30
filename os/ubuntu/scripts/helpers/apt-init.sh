#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
# Configure apt to always assume Y
echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

cp /etc/apt/sources.list /etc/apt/sources.list.origin
set +e
scurl --connect-timeout 1 http://metadata.tencentyun.com/latest/meta-data/instance-id
rv=$?
set -e
if [[ ${rv} -eq 0 ]];then
  sed -i 's|^\(\s*deb\s*\)http://security.ubuntu.com/ubuntu/|\1http://mirrors.tencentyun.com/ubuntu|' /etc/apt/sources.list
  sed -i 's|^\(\s*deb\s*\)http://archive.ubuntu.com/ubuntu/|\1http://mirrors.tencentyun.com/ubuntu|' /etc/apt/sources.list
  exit 0
fi


# Use apt-fast for parallel downloads
apt-get update
apt-get install -yqq apt-file
apt-get install -yqq aria2
apt-get install -yqq software-properties-common
add-apt-repository -y ppa:apt-fast/stable
apt-get update
apt-get install -yqq apt-fast


apt-get -yqq update
apt-get -yqq dist-upgrade
systemctl disable apt-daily.service
systemctl disable apt-daily.timer
systemctl disable apt-daily-upgrade.timer
systemctl disable apt-daily-upgrade.service
