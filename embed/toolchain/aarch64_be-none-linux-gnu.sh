#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
URL='https://developer.arm.com/-/media/Files/downloads/gnu-a/9.2-2019.12/binrel/gcc-arm-9.2-2019.12-x86_64-aarch64_be-none-linux-gnu.tar.xz?revision=eb9e778e-86af-4c34-a9f6-036f1b870f93&la=en&hash=0C174A05CB081010BECBF91049AF493302E017C6'

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

case ${1} in
  download)
    download()
  ;;
  *)
    echo ""
  ;;
esac
