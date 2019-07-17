#!/bin/sh
set -eu

if [ $# -eq 0 ]; then
    while true; do
        sleep 3600;
    done
fi

exec "$@"
