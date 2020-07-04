#!/bin/bash
################################################################################
##  File:  aliyun-cli.sh
##  Desc:  Installs Tencent Cloud CLI
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/apt.sh
source $HELPER_SCRIPTS/cloud.sh

if runon_tencentcloud;then
  PIP_OPT="--index-url http://mirrors.tencentyun.com/pypi/simple
  --trusted-host mirrors.tencentyun.com"
else if runon_alicloud
  PIP_OPT="--index-url http://mirrors.cloud.aliyuncs.com/pypi/simple \
  --trusted-host mirrors.cloud.aliyuncs.com"
else
  PIP_OPT=""
fi
 pip3 install ${PIP_OPT} coscmd coscmd
 pip3 install ${PIP_OPT} coscmd tccli

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v coscmd ; then
    echo "coscmd was not installed"
    exit 1
fi
if ! command -v tccli ; then
    echo "tccli was not installed"
    exit 1
fi
# Document what was added to the image
coscmd_version="$(coscmd --version|head -n 1)"
tccli_version="$(tccli version)"
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "coscmd, Tencent Cos Cli ($coscmd_version)"

DocumentInstalledItem "tccli, Tencent Cloud Cli ($tccli_version)"