#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh
source ${SCRIPT_DIR}/0helper-etc-environment.sh

if runon_cn;then
  URL='https://mirrors.cloud.tencent.com/elasticstack/7.x/yum/7.8.0/filebeat-7.8.0-x86_64.rpm'
else
  URL='https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.8.0-x86_64.rpm'
fi



function get_filename_from_url()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+rpm/}')
  echo "$fname"
}
function get_filename_from_path()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+rpm/}')
  echo "$fname"
}

TC_DIR=/tmp
FILE_NAME=$(get_filename_from_url "$URL")
SAVE_FILE="${TC_DIR}/${FILE_NAME}"

function download()
{
  mkdir -p ${TC_DIR}
  echo "try download ${FILE_NAME}"
  local SAVE_FILE="${TC_DIR}/${FILE_NAME}"
  if [[ ! -f ${SAVE_FILE} ]];then
    curl -o ${SAVE_FILE} -L ${URL}
    ls ${TC_DIR}
  else
    echo "${SAVE_FILE} already download!"
  fi
}

function extra-tc()
{
  rpm -vi ${SAVE_FILE}
  set +e
  /bin/rm -f ${SAVE_FILE}
  set -e
}

download
extra-tc

DocumentInstalledItem "Filebeat: ${FILE_NAME}"
