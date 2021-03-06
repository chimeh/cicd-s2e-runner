#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"

TC_DIR=/s2erunner-src/os/centos/scripts/installers
TCEB_DIR=/s2erunner-src/embed/toolchain

bash /s2erunner-src/os/centos/scripts/0helper-yum.sh
bash /s2erunner-src/os/centos/scripts/0helper-basic.sh

TCLIST=(
  c_c++.sh
  github-cli.sh
  gitlab-cli.sh
  gitlab-runner.sh
  cloud-aliyun-tencent-huawei-cli.sh
)

# build time, runtime toolchains
cd ${TC_DIR}
for s in ${TCLIST[*]}
do
   set +e; ls ${TC_DIR}/$s >/dev/null 2>&1; rv=$? ; set -e
   if [ ${rv} -eq 0 ];then
       echo "###${TC_DIR}/$s"
       bash ${TC_DIR}/validate-disk-space.sh
       set +e; bash ${TC_DIR}/$s; ok=$?;set -e
       if [ ${ok} -ne 0 ];then echo $s >> /error.txt;fi
   else
       echo "*** not install $s, $s not exist!" >> /error.txt;
   fi
done

set +e
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/aarch64_be-none-linux-gnu.sh  2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/aarch64-none-elf.sh install 2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/aarch64-none-linux-gnu.sh  2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/gcc-arm-none-eabi.sh install 2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/msp430-gcc.sh install 2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/riscv-none-elf-gcc.sh install 2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/android.sh  2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
bash ${TCEB_DIR}/injectenv.sh  2>> /error.txt;
bash ${TC_DIR}/validate-disk-space.sh
set -e


bash /s2erunner-src/os/centos/scripts/installers/cleanup.sh;
touch /error.txt; cat /error.txt; /bin/rm /error.txt;

