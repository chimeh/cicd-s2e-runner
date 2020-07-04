#!/bin/bash
################################################################################
##  File:  aliyun-cli.sh
##  Desc:  Installs Huawei Cloud CLI
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/apt.sh

# Install Alibaba Cloud CLI
URL=https://obs-community.obs.cn-north-1.myhuaweicloud.com/obsutil/current/obsutil_linux_amd64.tar.gz
wget -P /tmp $URL
cd /tmp
tar xzvf /tmp/obsutil_linux_amd64.tar.gz
mv /tmp/obsutil_linux_amd64_*/obsutil /usr/local/bin/

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v obsutil ; then
    echo "obsutil was not installed"
    exit 1
fi

# Document what was added to the image
obsutil_version="$(obsutil version | head -n 1)"
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "obsutil, Huawei Cloud obs cli ($obsutil_version)"