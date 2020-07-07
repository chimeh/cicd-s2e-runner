#!/bin/bash
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"

OTHER_DOC_UTIL="${SCRIPT_DIR}/../../os/centos/helpers/document.sh"
if [[ -f "${OTHER_DOC_UTIL}" ]];then
  source"${OTHER_DOC_UTIL}"
else
  echo "can't find ${OTHER_DOC_UTIL}"
  exit 1
fi