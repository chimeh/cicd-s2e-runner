#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/cloud.sh

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
