#!/bin/bash

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh
source ${SCRIPT_DIR}/0helper-etc-environment.sh

set +e
chmod -R 777 /var/log/gitlab-job-metric


injectpath "/s2e"
injectpath "/s2e/custom/tools"
injectpath "/s2e/tools"

