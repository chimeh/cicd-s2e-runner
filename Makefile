CUR_DIR := $(realpath $(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
.PHONY: phony-all
phony-all: docker-centos

.PHONY: docker-centos
docker-centos:
	bash ${CUR_DIR}/docker.sh ${CUR_DIR}/Dockerfile.centos

.PHONY: docker-ubuntu
docker-ubuntu:
	bash ${CUR_DIR}/docker.sh ${CUR_DIR}/Dockerfile.ubuntu
