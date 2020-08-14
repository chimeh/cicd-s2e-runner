#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh

set +e
mkdir /home/actions-runner && cd /home/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.272.0/actions-runner-linux-x64-2.272.0.tar.gz
tar xzf /home/actions-runner/actions-runner-linux-x64-2.272.0.tar.gz -C /home/actions-runner
/bin/rm -f /home/actions-runner/actions-runner-linux-x64-2.272.0.tar.gz
DocumentInstalledItem "github-runner(action): linux-x64-2.272.0 "
set -e