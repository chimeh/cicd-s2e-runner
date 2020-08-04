#!/bin/bash
################################################################################
##  File:  cmake.sh
##  Desc:  Installs CMake
################################################################################
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

# Source the helpers for use with the script
source ${SCRIPT_DIR}/0helper-document.sh

if ! command -v make; then
    yum install -y make
fi

# Test to see if the software in question is already installed, if not install it
echo "Checking to see if the installer script has already been run"
if command -v cmake; then
    echo "cmake is already installed"
else
	curl -sL https://cmake.org/files/v3.17/cmake-3.17.0-Linux-x86_64.sh -o cmakeinstall.sh \
	&& chmod +x cmakeinstall.sh \
	&& ./cmakeinstall.sh --prefix=/usr/local --exclude-subdir \
	&& rm cmakeinstall.sh
fi


# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
for i in make cmake; do
  if ! command -v $i; then
      echo "$i was not installed"
      exit 1
  fi
done

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Make:"
DocumentInstalledItemIndent "cmake ($(cmake --version | head -n 1))"
DocumentInstalledItemIndent "make $(make --version | head -n 1 |  perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
