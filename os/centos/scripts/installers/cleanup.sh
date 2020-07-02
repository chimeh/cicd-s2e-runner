#!/bin/bash

source ${SCRIPT_DIR}/../helpers/etc-environment.sh
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

# after cleanup
after=$(df / -Pm | awk 'NR==2{print $4}')

# display size
 echo "Before: $before MB"
 echo "After : $after MB"
 echo "Delta : $(($after-$before)) MB"
