#!/bin/bash
#author: jimin.huang
#email: jimin.huang@nx-engine.com

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
echo "${set -e}"
echo "put your Tool in directory as ${0}"