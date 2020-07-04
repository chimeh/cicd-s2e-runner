CUR_DIR := $(realpath $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
.PHONY: phony-all
phony-all: docker-centos-dev

.PHONY: docker-centos-dev
docker-centos-dev:
	bash ${CUR_DIR}/scripts/docker.sh ${CUR_DIR}/Dockerfile.centos dev

.PHONY: docker-centos-pre
docker-centos-pre:
	bash ${CUR_DIR}/scripts/docker.sh ${CUR_DIR}/Dockerfile.centos pre
