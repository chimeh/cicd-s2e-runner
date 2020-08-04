#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

# Source the helpers for use with the script
source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh


## Alibaba
# Install Alibaba Cloud CLI
URL=$(curl -s https://api.github.com/repos/aliyun/aliyun-cli/releases/latest | jq -r '.assets[].browser_download_url | select(contains("aliyun-cli-linux"))')
URL_FALLBACK=https://github.com/aliyun/aliyun-cli/releases/download/v3.0.49/aliyun-cli-linux-3.0.49-amd64.tgz
wget -P /tmp ${URL:-${URL_FALLBACK}}
cd /tmp 
tar xzvf $(/bin/ls /tmp/aliyun-cli-linux-*-amd64.tgz)
mv aliyun /usr/local/bin


# Tencent
if runon_tencentcloud;then
  PIP_OPT="--index-url http://mirrors.tencentyun.com/pypi/simple
  --trusted-host mirrors.tencentyun.com"
elif runon_aliyun;then
  PIP_OPT="--index-url http://mirrors.cloud.aliyuncs.com/pypi/simple \
  --trusted-host mirrors.cloud.aliyuncs.com"
else
  PIP_OPT=""
fi
 pip3 install ${PIP_OPT} coscmd coscmd
 pip3 install ${PIP_OPT} coscmd tccli

# Huawei
URL=https://obs-community.obs.cn-north-1.myhuaweicloud.com/obsutil/current/obsutil_linux_amd64.tar.gz
wget -P /tmp $URL
tar xzvf /tmp/obsutil_linux_amd64.tar.gz
mv /tmp/obsutil_linux_amd64_*/obsutil /usr/local/bin/

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
cmd_test=(aliyun coscmd tccli obsutil)
for cmd in ${cmd_test[*]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
    exit 1
  fi
done
# Document what was added to the image
aliyun_version="$(aliyun --version | grep "Alibaba Cloud Command Line Interface Version" | cut -d " " -f 7)"
coscmd_version="$(coscmd --version|head -n 1)"
tccli_version="$(tccli version)"
obsutil_version="$(obsutil version | head -n 1)"

echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Cloud CLI:"
DocumentInstalledItemIndent "aliyun, Alibaba Cloud CLI ($aliyun_version)"
DocumentInstalledItemIndent "coscmd, Tencent CloudCos Cli ($coscmd_version)"
DocumentInstalledItemIndent "tccli,  Tencent Cloud Cli ($tccli_version)"
DocumentInstalledItemIndent "obsutil,Huawei Cloud obs Cli (${obsutil_version})"
