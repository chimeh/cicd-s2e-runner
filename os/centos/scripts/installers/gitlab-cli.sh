#!/bin/bash
################################################################################
##  File:  aliyun-cli.sh
##  Desc:  Installs Gitlab CLI
################################################################################

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh


if runon_tencentcloud;then
  PIP_OPT="--index-url http://mirrors.tencentyun.com/pypi/simple
  --trusted-host mirrors.tencentyun.com"
elif runon_aliyun;then
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
