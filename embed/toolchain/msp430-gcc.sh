#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
source ${SCRIPT_DIR}/document.sh
URL='http://software-dl.ti.com/msp430/msp430_public_sw/mcu/msp430/MSPGCC/9_2_0_0/export/msp430-gcc-9.2.0.50_linux32.tar.bz2'



function get_filename_from_url()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+tar.(xz|gz|bz2|zip|bzip2)/}')
  echo "$fname"
}
function get_filename_from_path()
{
  fname=$(echo "$1" | perl -n -e 'my $url=$_; @arr = split(/[\/\?=&]/, $url);foreach my $el (@arr){print "$el\n" if $el =~ /.+tar.(xz|gz|bz2|zip|bzip2)/}')
  echo "$fname"
}

TC_DIR=/opt/tcpkg
FILE_NAME=$(get_filename_from_url "$URL")

function download()
{
  mkdir -p ${TC_DIR}
  echo "try download ${FILE_NAME}"
  SAVE_FILE="${TC_DIR}/${FILE_NAME}"
  if [[ ! -f ${SAVE_FILE} ]];then
    curl -o ${SAVE_FILE} -L ${URL}
    ls ${TC_DIR}
  else
    echo "${SAVE_FILE} already download!"
  fi
}

download

DocumentInstalledItem "cross toolchain: ${SAVE_FILE}"
