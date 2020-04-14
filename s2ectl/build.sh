#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
cd ${SCRIPT_DIR}

make test cover bin 
