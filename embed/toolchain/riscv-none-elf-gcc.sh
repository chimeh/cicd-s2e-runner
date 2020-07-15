#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
source ${SCRIPT_DIR}/document.sh

set +e
TC_DIR=/opt/embed
FILE_NAME=$(get_filename_from_url "$URL")
SAVE_FILE="${TC_DIR}/${FILE_NAME}"

function build() {
  yum install -y autoconf automake python3 libmpc-devel
  yum install -y mpfr-devel gmp-devel gawk  bison flex
  yum install -y texinfo patchutils gcc gcc-c++ zlib-devel expat-devel
  DIR=$(mktemp -d /tmp/riscv.XXX)
  git clone --recursive https://github.com/riscv/riscv-gnu-toolchain ${DIR}
  cd ${DIR}
  mkdir -p ${TC_DIR}/riscv
  ./configure --prefix=${TC_DIR}/riscv
  make install

}
function download()
{
  mkdir -p "${TC_DIR}"
  build
}
function extra-tc()
{
  echo ""
}

if [[ $# -gt 0 ]];then
  download
  extra-tc
fi

DocumentInstalledItem "Cross toolchain: $()"
DocumentInstalledItemIndent "run ${THIS_SCRIPT})"