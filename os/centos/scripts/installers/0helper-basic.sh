#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh

yum makecache
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
  m4
  nmap-ncat
  openssh-clients
  openssl-devel
  parallel
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
  wqy-microhei-fonts
  zip
  zlib-devel
)

cmd_test=(
bash
curl
find
ftp
jq
rsync
scp
shellcheck
ssh
sshpass
sudo
tree
unzip
wget
zip
)
for p in ${pkg[*]}; do
  echo "Install $p"
  yum install -y $p
done

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
for cmd in ${cmd_test[@]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
    exit 1
  fi
done

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Basic shell cli, such as:"
cmd_test_sort=($(echo ${cmd_test[@]} | tr ' ' '\n' | sort))
cmd_test_sort_len=${#cmd_test[@]}
line=""
for ((i=0;i<=${cmd_test_sort_len};i++));do
  if [[ $i -eq ${cmd_test_sort_len} ]];then
    DocumentInstalledItemIndent "$line"
    break
  fi
  if [[ $i -gt 0 ]];then
    if [[ $(($i % 8)) -eq 0 ]];then
      DocumentInstalledItemIndent "$line"
      line=""
    else
      line="$line ${cmd_test_sort[i]}"
    fi
  else
      line="$line ${cmd_test_sort[i]}"
  fi
done

bash ${SCRIPT_DIR}/0helper-make.sh
bash ${SCRIPT_DIR}/0helper-scm-tools.sh
bash ${SCRIPT_DIR}/0helper-python.sh

