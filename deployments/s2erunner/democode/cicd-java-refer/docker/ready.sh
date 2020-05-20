#!/bin/sh
# readiness checker

curl -f localhost:8080/actuator/health
rv=$?
exit ${rv}
