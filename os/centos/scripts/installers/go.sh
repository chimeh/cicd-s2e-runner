#!/bin/bash

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/../helpers/document.sh
source ${SCRIPT_DIR}/../helpers/cloud.sh
source ${SCRIPT_DIR}/../helpers/etc-environment.sh


GO_VERSION=1.14.1
wget -q -P /root/ts https://mirror.azure.cn/go/go${GO_VERSION}.linux-amd64.tar.gz
tar -xzf /root/ts/go${GO_VERSION}.linux-amd64.tar.gz -C /opt
rm -rf /root/ts

appendEtcEnvironmentPath "/opt/go/bin"

for cmd in go; do
    if ! command -v $cmd; then
        echo "$cmd was not installed or found on path"
        exit 1
    fi
done

echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "go ($(go version))"
