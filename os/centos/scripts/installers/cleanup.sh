#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
source ${SCRIPT_DIR}/0helper-etc-environment.sh
# before cleanup
before=$(df / -Pm | awk 'NR==2{print $4}')

# clears out the local repository of retrieved package files
# It removes everything but the lock file from /var/cache/apt/archives/ and /var/cache/apt/archives/partial
yum clean all
rm -rf /var/cache/yum
rm -rf /tmp/*

if command -v go; then
    go clean
fi
touch ${DOC_FILE:-/etc/profile.d/sh.local}
cat ${DOC_FILE}
cat /etc/profile.d/sh.local
source /etc/profile

set +e;
yum clean all
/bin/rm -rf /var/cache/yum
/bin/rm -rf /root/ts
ls /opt/embed/*
go clean -cache
npm cache clean --force
/bin/rm -rf ~/go/*
/bin/rm -f /opt/embed/*tar*
/bin/rm -rf /tmp/*
set -e;

# after cleanup
after=$(df / -Pm | awk 'NR==2{print $4}')

# display size
 echo "Before: $before MB"
 echo "After : $after MB"
 echo "Delta : $(($after-$before)) MB"
