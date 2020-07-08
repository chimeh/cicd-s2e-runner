#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
source ${SCRIPT_DIR}/document.sh
URL='https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64-none-elf.tar.xz?revision=ea238776-c7c7-43be-ba0d-40d7f594af1f&la=en&hash=2937ED76D3E6B85BA511BCBD46AE121DBA5268F3'

function get_filename_from_url()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+tar.(xz|gz|zip|bzip2)/}')
  echo "$fname"
}
function get_filename_from_path()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+tar.(xz|gz|zip|bzip2)/}')
  echo "$fname"
}

TC_DIR=/opt/tcpkg
FILE_NAME=$(get_filename_from_url "$URL")

function download()
{
  mkdir -p "${TC_DIR}"
  echo "try download ${FILE_NAME}"
  local SAVE_FILE="${TC_DIR}/${FILE_NAME}"
  if [[ ! -f ${SAVE_FILE} ]];then
    curl -o ${SAVE_FILE} -L ${URL}
    ls ${TC_DIR}
  else
    echo "${SAVE_FILE} already download!"
  fi
}

download

DocumentInstalledItem "cross toolchain: ${FILE_NAME}"