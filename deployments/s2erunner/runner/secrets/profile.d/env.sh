export ENABLE_SONAR=0
export DOCKER_REPO=docker.io
export DOCKER_NS=bettercode


# speed up docker build when run on tencent cloud, see https://mirrors.cloud.tencent.com/
# let http://mirrors.cloud.tencent.com resolve to http://mirrors.tencentyun.com when docker build
S2I_DOCKER_OPT="--add-host mirrors.cloud.tencent.com:169.254.0.3 "

grep -qxF '10.99.16.41 rancher.ops' /etc/hosts || echo '10.99.16.41 rancher.ops' >> /etc/hosts
grep -qxF '10.128.2.12 harbor.benload.com' /etc/hosts || echo '10.128.2.12 harbor.benload.com' >> /etc/hosts
