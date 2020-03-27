export NEXUS_REPO=https://maven.aliyun.com/repository/public
export NEXUS_RELEASE=https://maven.aliyun.com/repository/releases
export NEXUS_SNAPSHOT=https://maven.aliyun.com/repository/snapshots


export ENABLE_SONAR=0
###################docker push repo
export DOCKER_REPO=docker.io
export DOCKER_NS=bettercode

###################delpoy destination, which kubernetes and namespace
export K8S_KUBECONFIG=/root/.kube/config
export K8S_KUBECONFIG_DEV=""
export K8S_KUBECONFIG_TEST=""
export K8S_KUBECONFIG_UAT=""
export K8S_KUBECONFIG_PROD=""

#export K8S_NS=default
#export K8S_NS_DEV=
#export K8S_NS_TEST=
#export K8S_NS_UAT=
#export K8S_NS_PRD=

################### deploy kubernetes ingress
export K8S_DOMAIN_INTERNAL=bu5-idc.nxengine.com
export K8S_DOMAIN_INTERNAL_DEV=""
export K8S_DOMAIN_INTERNAL_TEST=""
export K8S_DOMAIN_INTERNAL_UAT=""
export K8S_DOMAIN_INTERNAL_PRD=""

export K8S_DOMAIN_PUBLIC=bu5-idc.cd
export K8S_DOMAIN_PUBLIC_DEV=""
export K8S_DOMAIN_PUBLIC_TEST=""
export K8S_DOMAIN_PUBLIC_UAT=""
export K8S_DOMAIN_PUBLIC_PRD=""

export INGRESS_PUBLIC_ENABLED=1
export INGRESS_PUBLIC_ENABLED_DEV=""
export INGRESS_PUBLIC_ENABLED_TEST=""
export INGRESS_PUBLIC_ENABLED_UAT=""
export INGRESS_PUBLIC_ENABLED_PRD=""

export INGRESS_INTERNAL_ENABLED=1
export INGRESS_INTERNAL_ENABLED_DEV=""
export INGRESS_INTERNAL_ENABLED_TEST=""
export INGRESS_INTERNAL_ENABLED_UAT=""
export INGRESS_INTERNAL_ENABLED_PRD=""

export INGRESS_CLASS_INTERNAL=nginx
export INGRESS_CLASS_INTERNAL_DEV=""
export INGRESS_CLASS_INTERNAL_DEV=""
export INGRESS_CLASS_INTERNAL_DEV=""
export INGRESS_CLASS_INTERNAL_DEV=""

export INGRESS_CLASS_PUBLIC=nginx
export INGRESS_CLASS_PUBLIC_DEV=""
export INGRESS_CLASS_PUBLIC_TEST=""
export INGRESS_CLASS_PUBLIC_UAT=""
export INGRESS_CLASS_PUBLIC_PRD=""


