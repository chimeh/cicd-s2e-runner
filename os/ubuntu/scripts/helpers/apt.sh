#!/bin/bash
################################################################################
##  File:  apt.sh
##  Desc:  This script contains helper functions for using dpkg and apt
################################################################################

## Use dpkg to figure out if a package has already been installed
## Example use:
## if ! IsInstalled packageName; then
##     echo "packageName is not installed!"
## fi
function IsInstalled {
    dpkg -S $1 &> /dev/null
}

cp /etc/apt/sources.list /etc/apt/sources.list.origin
# Configure apt to always assume Y
echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

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
apt-get install -y aria2
apt-get install -y python3-software-properties
apt-get install -y python3-software-common
add-apt-repository -y apt-utilsppa:apt-fast/stable
apt-get update
apt-get install -y apt-fast
