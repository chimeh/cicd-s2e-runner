#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh

yum install -y supervisor

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
cmd_test=(
  supervisord
)
for cmd in ${cmd_test[*]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
  fi
done
# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "gcc $(supervisord --version | head -n 1 | perl -ne '$_ =~ /\b(\d+[-\S]*)/;print $1' -)"
