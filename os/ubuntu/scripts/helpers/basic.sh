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
  bsd-mailx
  curl
  dbus
  dnsutils
  dpkg
  expect
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
  pigz
  pkg-config
  rpm
  rsync
  shellcheck
  ssh
  sshpass
  sudo
  telnet
  texinfo
  time
  tk
  tree
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



##################################################git

## Install git
add-apt-repository ppa:git-core/ppa -y
apt-get update
apt-get install git -y
git --version

# Install git-lfs
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash
apt-get install -y --no-install-recommends git-lfs

# Install git-ftp
apt-get install git-ftp -y

# Run tests to determine that the software installed as expected
echo "Testing git installation"
if ! command -v git; then
    echo "git was not installed"
    exit 1
fi
echo "Testing git-lfs installation"
if ! command -v git-lfs; then
    echo "git-lfs was not installed"
    exit 1
fi
echo "Testing git-ftp installation"
if ! command -v git-ftp; then
    echo "git-ftp was not installed"
    exit 1
fi

# Document what was added to the image
echo "Lastly, document the installed versions"
DocumentInstalledItem "Git/SVN:"
# git version 2.20.1
DocumentInstalledItemIndent "git ($(git --version 2>&1 | cut -d ' ' -f 3))"
# git-lfs/2.6.1 (GitHub; linux amd64; go 1.11.1)
DocumentInstalledItemIndent "git lfs, Git Large File Storage (LFS) ($(git-lfs --version 2>&1 | cut -d ' ' -f 1 | cut -d '/' -f 2))"
DocumentInstalledItemIndent "git ftp, ($(git-ftp --version | cut -d ' ' -f 3))"

##################################################svn
# Install Subversion
apt-get install -y --no-install-recommends subversion

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v svn; then
    echo "Subversion (svn) was not installed"
    exit 1
fi

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItemIndent "svn, Subversion ($(svn --version | head -n 1))"

##################################################mercurial

if isUbuntu16 ; then
    # Install Mercurial from the mercurial-ppa/releases repository for the latest version for Ubuntu16.
    # https://www.mercurial-scm.org/wiki/Download
    add-apt-repository ppa:mercurial-ppa/releases -y
    apt-get update
fi

apt-get install -y --no-install-recommends mercurial

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v hg; then
    exit 1
fi

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItemIndent "hg, Mercurial ($(hg --version | head -n 1))"
