#!/bin/bash
################################################################################
##  File:  basic.sh
##  Desc:  Installs basic command line utilities and dev packages
################################################################################

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/apt.sh
source $HELPER_SCRIPTS/os.sh

set -e

pkg_list=(
  bison
  curl
  dbus
  dnsutils
  dpkg
  fakeroot
  file
  flex
  ftp
  gnupg2
  iproute2
  iputils-ping
  jq
  lib32z1
  libgbm-dev
  libgconf-2-4
  libgtk-3-0
  libsecret-1-dev
  libunwind8
  libxkbfile-dev
  libxss1
  locales
  m4
  netcat
  openssh-client
  parallel
  pkg-config
  rpm
  rsync
  shellcheck
  ssh
  sudo
  telnet
  texinfo
  time
  tk
  tzdata
  unzip
  upx
  vim
  wget
  xorriso
  xvfb
  xz-utils
  zip
  zstd
  zsync
)

cmd_list=(
  curl
  file
  ftp
  jq
  netcat
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
  vim
  flex
)

if isUbuntu20; then
  echo "Install python2"
  apt-get install -y --no-install-recommends python-is-python2
fi

echo "Install libcurl"
if isUbuntu18; then
  libcurelVer="libcurl3"
fi

if isUbuntu20; then
  libcurelVer="libcurl4"
fi

apt-get install -y --no-install-recommends $libcurelVer

for package in ${pkg_list[*]}; do
  echo "Install $package"
  apt-get install -y --no-install-recommends $package
done

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
for cmd in ${cmd_list[*]}; do
  if ! command -v $cmd; then
    echo "$cmd was not installed"
    exit 1
  fi
done

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Basic packages:"
for package in ${pkg_list[*]}; do
  DocumentInstalledItemIndent $package
done

DocumentInstalledItemIndent "$libcurelVer"
