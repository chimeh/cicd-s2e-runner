#!/bin/bash

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh

#yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo  http://download.docker.com/linux/centos/docker-ce.repo

if runon_tencentcloud;then
echo "on tencent cloud, use tencent mirror"
sed -i 's+download.docker.com+mirrors.cloud.tencent.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
fi

echo "DOCKER_CLI_EXPERIMENTAL=enabled" | tee -a /etc/environment
yum install -y docker-ce docker-compose

for cmd in docker docker-compose; do
    if ! command -v $cmd; then
        echo "$cmd was not installed or found on path"
        exit 1
    fi
done

echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "docker"
DocumentInstalledItemIndent "docker ($(docker version | egrep Version | head -n 1 ))"
DocumentInstalledItemIndent "docker-compose ($(docker-compose  version|head -n 1))"
