#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh
# Tencent Cloud
if runon_tencentcloud;then
echo "on tencent cloud, use gitlab-runner mirror"
cat > /etc/yum.repos.d/gitlab-runner.repo << 'EOF'
[gitlab-runner]
name=gitlab-runner
baseurl=http://mirrors.cloud.tencent.com/gitlab-runner/yum/el$releasever/
repo_gpgcheck=0
gpgcheck=0
enabled=1
gpgkey=https://packages.gitlab.com/gpg.key
EOF
else
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | bash
fi

yum install -y --nogpgcheck gitlab-runner

DocumentInstalledItem "gitlab-runner: $(gitlab-runner --version | head -n 1)"
