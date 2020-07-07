#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
URL='https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2'


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

TC_DIR=${TC_DIR:/opt/tcpkg}
TC_EXTRA_DIR=${TC_DIR:/opt/tc}
FILE_NAME=$(get_filename_from_url "$URL")

function download()
{
  mkdir -p ${TC_DIR}
  echo "try download ${FILE_NAME}"
  SAVE_FILE="${TC_DIR}/${FILE_NAME}"
  if [[ ! -f ${SAVE_FILE} ]];then
    curl -O ${SAVE_FILE} -L ${URL}
  else
    echo "${SAVE_FILE} already download!"
  fi
}

case ${1} in
  download)
    download()
  ;;
  *)
    echo ""
  ;;
esac
