export PATH=/s2e/tools:${PATH}

export NEXUS_REPO=https://maven.aliyun.com/repository/public
export NEXUS_RELEASE=https://maven.aliyun.com/repository/releases
export NEXUS_SNAPSHOT=https://maven.aliyun.com/repository/snapshots

export ENABLE_SONAR=0
export DOCKER_REPO=docker.io
export DOCKER_NS=bettercode

export K8S_AUTOCD=0
export K8S_NS=default
export K8S_DOMAIN_INTERNAL=bu5-dev.cd
export K8S_DOMAIN_PUBLIC=bu5-dev.nxengine.com


export INGRESS_PUBLIC_ENABLED=true
export INGRESS_INTERNAL_ENABLED=true
export INGRESS_CLASS_INTERNAL=nginx
export INGRESS_CLASS_PUBLIC=nginx


export TEST_NOTICE_USER_EMAIL=shufang.gui@nx-engine.com
export UAT_NOTICE_USER_EMAIL=shufang.gui@nx-engine.com
export PROD_NOTICE_USER_EMAIL=jimin.huang@nx-engine.com

echo "10.99.16.41 rancher.ops" >> /etc/hosts