#!/bin/bash
################################################################################
##  File:  validate-disk-space.sh
##  Desc:  Validate free disk space
################################################################################

availableSpaceMB=$(df / -hm | sed 1d | awk '{ print $4}')
minimumFreeSpaceMB=16000
gcminimumFreeSpaceMB=20000

echo "Available disk space: $availableSpaceMB MB"

if [ "$RUN_VALIDATION" != "true" ]; then
    echo "Skipping validation disk space..."
    exit 0
fi
if [ $availableSpaceMB -le $gcminimumFreeSpaceMB ]; then
  THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
  #automatic detection TOPDIR
  SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
  bash ${SCRIPT_DIR}/cleanup.sh
fi
if [ $availableSpaceMB -le $minimumFreeSpaceMB ]; then
    echo "Not enough disk space on the image (minimum available space: $minimumFreeSpaceMB MB)"
    exit 1
fi