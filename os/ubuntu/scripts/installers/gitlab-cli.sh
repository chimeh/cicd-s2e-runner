#!/bin/bash
################################################################################
##  File:  aliyun-cli.sh
##  Desc:  Installs Gitlab CLI
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
 pip3 install ${PIP_OPT} python-gitlab

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v gitlab ; then
    echo "gitlab was not installed"
    exit 1
fi

# Document what was added to the image
gitlab_version="$(gitlab --version|head -n 1)"
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "gitlab, cli for gitlab  ($gitlab_version)"
