#!/bin/sh
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
echo "run $0"
#automatic detection SCRIPT_DIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
echo "THIS_SCRIPT=${THIS_SCRIPT}"
echo "SCRIPT_DIR=${SCRIPT_DIR}"
