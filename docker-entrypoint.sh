#!/bin/sh
set -eu

if [ $# -eq 0 ]; then
    mkdir -pv /tmp/xopsx;
    nginx -g "daemon off;"
fi

exec "$@"
