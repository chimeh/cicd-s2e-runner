#!/bin/sh
# liveness.sh checker

# checkout port is open
nc -zv localhost 8080
rv=$?

exit ${rv}
