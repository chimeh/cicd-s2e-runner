#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh

yum groupinstall -y 'Development Tools' 'Legacy UNIX Compatibility'

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
cmd_test=(
  gcc
  g++
  gdb
  ar
  as
  objcopy
  ld
)
for cmd in ${cmd_test[*]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
  fi
done
# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "C/C++ Toolchain:"
DocumentInstalledItemIndent "gcc $(gcc --version | head -n 1 | perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
DocumentInstalledItemIndent "g++ $(g++ --version | head -n 1 | perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
DocumentInstalledItemIndent "gdb $(gdb --version | head -n 1 | perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
DocumentInstalledItemIndent "binutils $(ld --version | head -n 1 |  perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
