#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-cloud.sh
source ${SCRIPT_DIR}/0helper-etc-environment.sh

# kubectl, helm2
KUBE_VERSION=v1.15.7
HELM2_VERSION=v2.12.2
wget -q http://mirror.azure.cn/kubernetes/kubectl/${KUBE_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl
wget -q http://mirror.azure.cn/kubernetes/helm/helm-${HELM2_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm2
chmod +x /usr/local/bin/helm2
ln -sf /usr/local/bin/helm2 /usr/local/bin/helm

# helm3
if ! command -v go; then
    echo "to build helm3, go must install first"
    exit 1
fi
if runon_tencentcloud;then
  echo "on tencent cloud, use tencent mirror"
  export GOPROXY="http://mirrors.cloud.tencent.com/go/,https://goproxy.cn,direct"
fi
mkdir -p /root/ts
cd /root/ts
git clone --depth 1 https://gitee.com/chimeh/helm.git
cd helm; git checkout ${HELM3_VERSION}
make -j2 -C .
cp /root/ts/helm/bin/helm /usr/local/bin/helm3
cd ~
rm -rf /root/ts

echo "check cmd run ok"
for cmd in kubectl helm helm2 helm3; do
    if ! command -v $cmd; then
        echo "$cmd was not installed or found on path"
        exit 1
    fi
done


DocumentInstalledItem "Kubernetes Cli:"
DocumentInstalledItemIndent "kubectl ($(kubectl version --client --short |& head -n 1))"
DocumentInstalledItemIndent "helm ($(helm version --short |& head -n 1))"
DocumentInstalledItemIndent "helm2 ($(helm2 version --short |& head -n 1))"
DocumentInstalledItemIndent "helm3 ($(helm3 version --short |& head -n 1))"

