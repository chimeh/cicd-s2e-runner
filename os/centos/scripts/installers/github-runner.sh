#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh

set +e
useradd   --home-dir /home/github-runner --user-group  --create-home --groups docker github-runner
mkdir /home/github-runner && cd /home/github-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.272.0/actions-runner-linux-x64-2.272.0.tar.gz
chown -R  github-runner:github-runner /home/github-runner/
#tar xzf /home/github-runner/actions-runner-linux-x64-2.272.0.tar.gz -C /home/github-runner
#/bin/rm -f /home/github-runner/actions-runner-linux-x64-2.272.0.tar.gz
# sudo -u github-runner ./config.sh --unattended --url https://github.com/bldyun --token xxxx --name "$(hostname)" --work /home/github-runner/_work
# export RUNNER_ALLOW_RUNASROOT=1 ;nohup  ./run.sh
# add '. /etc/profile' to run.sh
DocumentInstalledItem "github-runner(action): linux-x64-2.272.0 "
set -e