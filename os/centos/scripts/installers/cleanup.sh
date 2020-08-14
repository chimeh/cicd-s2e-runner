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


set +e;
yum clean all
/bin/rm -rf /var/cache/yum
/bin/rm -rf /root/ts >/dev/null 2>&1
ls /opt/embed/* >/dev/null 2>&1
go clean -cache >/dev/null 2>&1
npm cache clean --force >/dev/null 2>&1
/bin/rm -rf ~/go/* >/dev/null 2>&1
/bin/rm -f /opt/embed/*tar* >/dev/null 2>&1
/bin/rm -rf /tmp/* >/dev/null 2>&1
set -e;

# after cleanup
after=$(df / -Pm | awk 'NR==2{print $4}')

# display size
 echo "Before: $before MB"
 echo "After : $after MB"
 echo "Delta : $(($after-$before)) MB"
