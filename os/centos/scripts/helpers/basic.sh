#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/document.sh

yum groupinstall -y 'Development Tools' 'Legacy UNIX Compatibility'

pkg=(
  bash
  bash-completion
  bash-completion-extras
  bind-utils
  ca-certificates
  curl
  expect
  file
  findutils
  ftp
  gnupg2
  initscripts
  iproute
  iputils
  jq
  nmap-ncat
  openssh-clients
  parallel
  redhat-lsb
  rsync
  ShellCheck
  sshpass
  sudo
  sudo
  telnet
  time
  tree
  tzdata
  unzip
  vim
  wget
  zip
)

cmd_test=(
  curl
  file
  ftp
  jq
  nc
  ssh
  parallel
  rsync
  shellcheck
  sudo
  telnet
  time
  unzip
  zip
  wget
  m4
  bison
  flex
)
for p in ${pkg[*]}; do
  echo "Install $p"
  yum install -y $p
done

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
for cmd in ${cmd_test[*]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
    exit 1
  fi
done

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Basic packages:"
for p in ${pkg[*]}; do
  DocumentInstalledItemIndent $p
done

bash ${SCRIPT_DIR}/scm-tools.sh
