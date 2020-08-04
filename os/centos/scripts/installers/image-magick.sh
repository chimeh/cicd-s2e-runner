#!/bin/bash

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh


# Install ImageMagick
yum install -y ImageMagick  ImageMagick-devel

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "ImageMagick $(convert --version | head -n 1| perl -ne '$_ =~ /\b((0|[1-9][0-9]*).(0|[1-9][0-9]*).(0|[1-9][0-9]*))/;print $1' -)"
