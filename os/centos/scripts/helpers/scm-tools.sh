#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/document.sh

DocumentInstalledItem "Scm Tools:"
##################################################git
GIT_VERSION=2.24.1
## Install git
mkdir -p /root/ts
yum install -y  openssl-devel zlib-devel curl-devel expat-devel gettext-devel
wget -q -P /root/ts "http://mirrors.ustc.edu.cn/kernel.org/software/scm/git/git-${GIT_VERSION}.tar.gz"
tar -xzf /root/ts/git-${GIT_VERSION}.tar.gz -C /root/ts
make -j2 prefix=/usr/local install -C /root/ts/git-${GIT_VERSION}
rm -rf /root/ts

# Install git-lfs
yum install --nogpgcheck -y git-lfs

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

# Document what was added to the image
echo "Lastly, document the installed versions"
# git version 2.20.1
DocumentInstalledItemIndent "git ($(git --version 2>&1 | cut -d ' ' -f 3))"
# git-lfs/2.6.1 (GitHub; linux amd64; go 1.11.1)
DocumentInstalledItemIndent "git lfs, Git Large File Storage (LFS) ($(git-lfs --version 2>&1 | cut -d ' ' -f 1 | cut -d '/' -f 2))"

##################################################svn
SVN_VERSION=1.8
set +a
source  /etc/os-release
set -a
cat > /etc/yum.repos.d/svn.repo <<EOF
[svn]
name=Wandisco SVN Repo
baseurl=http://opensource.wandisco.com/centos/${VERSION_ID}/svn-1.8/RPMS/$(uname -m)
enabled=1
gpgcheck=0
EOF
yum --disablerepo=* --enablerepo=base,extras,updates,epel,svn makecache
yum erase -y subversion*
yum --disablerepo=* --enablerepo=svn install -y subversion


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
yum --disablerepo=* --enablerepo=base,extras,updates,epel install -y  mercurial

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! command -v hg; then
    exit 1
fi

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItemIndent "hg, Mercurial ($(hg --version | head -n 1))"

