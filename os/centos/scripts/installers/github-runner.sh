#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh

# Create a folder
mkdir -p github-runner && cd actions-runner
# Download the latest runner package
curl -O -L https://github.com/actions/runner/releases/download/v2.267.1/actions-runner-linux-x64-2.267.1.tar.gz
# Extract the installer
tar xzf ./actions-runner-linux-x64-2.267.1.tar.gz


DocumentInstalledItem "github-runner(action): v2.267.1 "
