#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh

curl https://packages.microsoft.com/config/centos/7/prod.repo > /tmp/packages-microsoft-com.repo
mv /tmp/packages-microsoft-com.repo /etc/yum.repos.d
yum makecache

yum install -y --nogpgcheck  dotnet-sdk-3.1

DocumentInstalledItem "gitlab-runner: $(gitlab-runner --version | head -n 1)"
