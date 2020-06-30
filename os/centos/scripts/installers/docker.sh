#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/cloud.sh
yum install -y yum-utils device-mapper-persistent-data lvm2
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
DocumentInstalledItemIndent "docker ($(python --version 2>&1))"
DocumentInstalledItemIndent "docker-compose ($(docker-compose  version|head -n 1))"
