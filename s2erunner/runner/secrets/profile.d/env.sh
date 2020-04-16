export ENABLE_SONAR=0
export DOCKER_REPO=docker.io
export DOCKER_NS=bettercode




grep -qxF '10.99.16.41 rancher.ops' /etc/hosts || echo '10.99.16.41 rancher.ops' >> /etc/hosts
grep -qxF '10.128.2.12 harbor.nx-engine.com' /etc/hosts || echo '10.128.2.12 harbor.nx-engine.com' >> /etc/hosts
