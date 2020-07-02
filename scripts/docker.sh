#!/bin/bash
set -e
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
SRC_TOP="$(realpath ${SCRIPT_DIR}/..)"

USAGE="
  usage:
  simple docker build script:
  I. build docker:
  $(basename $(realpath $0)) [/path/to/your-dockerfile] docker-build
  II. build docker then push:
  export DOCKER_REPO=
  export DOCKER_NS=
  export DOCKER_USER=
  export DOCKER_PASS=
  $(basename $(realpath $0)) [/path/to/your-dockerfile] docker-push
  III. genarate docker-compose
  $(basename $(realpath $0)) [/path/to/your-dockerfile] compose-gen
  $(basename $(realpath $0)) [/path/to/your-dockerfile] compose-test
  IV. develment phase 
  $(basename $(realpath $0)) [/path/to/your-dockerfile] dev
  $(basename $(realpath $0)) [/path/to/your-dockerfile] pre
  $(basename $(realpath $0)) [/path/to/your-dockerfile] release
"

if [[ $# -lt 1 ]];then
    if [[ -f ${PWD}/Dockerfile ]];then
      DOCKERFILE=${PWD}/Dockerfile
    else
      echo "${USAGE}"
      exit 1
    fi
else
    GIVE_DOCKERFILE=$1
    if [[ -f ${GIVE_DOCKERFILE} ]];then
      DOCKERFILE=$(realpath ${GIVE_DOCKERFILE} )
    else
      echo "error, Dockerfile not found"
      echo "${USAGE}"
      exit 1
    fi
fi

if [[ $# -gt 0 ]];then
    ACTION=$2
else
    ACTION="docker-build"
fi

DOCKERFILE_DIR=$(dirname "$(realpath "${DOCKERFILE}")")
IMG_TMP=$(echo "$(basename ${DOCKERFILE_DIR})-$(basename ${DOCKERFILE})" | tr '[A-Z]' '[a-z]')
ARTIFACT_DIR="${SRC_TOP}/.s2i/"

function do_docker_build() {

  docker build . --file ${DOCKERFILE} --tag ${IMG_TMP}
  mkdir -p ${ARTIFACT_DIR}
  set +e
  echo "Docker image size: "$(docker image inspect ${IMG_TMP} --format='{{.Size}}' ) | tee -a ${ARTIFACT_DIR}/buildnote.md

  cid=$(docker create ${IMG_TMP})
  docker cp $cid:/doc_file.txt - > ${DOCKERFILE}.md 2>/dev/null
  docker cp $cid:/doc_file.txt - > ${DOCKERFILE}.md 2>/dev/null
  docker rm -v $cid
  cat ${DOCKERFILE}.md | tee -a {ARTIFACT_DIR}/buildnote.md
  rm -f ${DOCKERFILE}.md
  set -e
}

function do_docker_push() {
  DOCKER_REPO=${DOCKER_REPO:-registry-1.docker.io}
  DOCKER_NS=${DOCKER_NS:-bettercode}
  DOCKER_USER=${DOCKER_USER:-bettercode}
  DOCKER_PASS=${DOCKER_PASS}

  if [[ -n ${DOCKER_PASS} ]];then
    docker login -u "${DOCKER_USER}" -p  "${DOCKER_PASS}" ${DOCKER_REPO}/${DOCKER_NS}
    IMAGE_URL=${DOCKER_REPO}/${DOCKER_NS}/$(basename ${PWD})
    # Change all uppercase to lowercase
    IMAGE_URL=$(echo $IMAGE_URL | tr '[A-Z]' '[a-z]')

    # Strip git ref prefix from version
    SRC_VERSION=$(echo "$(git describe  --tags --always|head -n 1)" | sed -e 's,.*/\(.*\),\1,')
    TAG=${SRC_VERSION}


    echo IMAGE_URL=$IMAGE_URL
    echo SRC_VERSION=$SRC_VERSION
    echo TAG=$TAG

    docker tag ${IMG_TMP} $IMAGE_URL:${TAG}
    docker tag ${IMG_TMP} $IMAGE_URL:latest
    docker push $IMAGE_URL:${TAG}
    docker push $IMAGE_URL:latest
    echo $IMAGE_URL:${TAG} | tee -a ${ARTIFACT_DIR}/img.txt
    set +e
    docker rmi ${IMG_TMP}
    docker rmi $IMAGE_URL:${TAG}
    docker rmi $IMAGE_URL:latest
    set -e
  else
    set +e
    docker rmi ${IMG_TMP}
    set -e
  fi
}

do_compose_gen() {
  mkdir -p ${ARTIFACT_DIR}
  if [[ ${USE_PUSHED_IMG} -gt 0 ]];then
    IMG="$(head -n 1 ${ARTIFACT_DIR}/img.txt)"
  else
    IMG=${IMG_TMP}
  fi
  echo ${IMG}
  /bin/cp -rf ${SRC_TOP}/deployments/s2erunner   cd ${ARTIFACT_DIR}
  bash ${ARTIFACT_DIR}/s2erunner/compose.sh
  /bin/cp -f ${ARTIFACT_DIR}/s2erunner/.tpl/docker-compose.yaml ${ARTIFACT_DIR}/s2erunner/docker-compose.yaml
  cat ${ARTIFACT_DIR}/s2erunner/.tpl/*.md >> ${ARTIFACT_DIR}/buildnote.md
}

do_compose_test() {
  cd ${ARTIFACT_DIR}/s2erunner
  docker-compose up --force-recreate
}

do_release_pre() {
  if ! command -v github-release; then
      go get github.com/github-release/github-release
  fi
  if [[ -z ${GITHUB_TOKEN} ]];then
      echo "GITHUB_TOKEN not set ,exit!"
      exit 1
  fi
  GITHUB_USER=${GITHUB_USER:-chimeh}
  GITHUB_REPO=${GITHUB_USER:-chimeh}
  TAG=$(head -n 1 ${SRC_TOP}/VERSION)

 github-release edit \
    --user ${GITHUB_USER} \
    --repo ${GITHUB_REPO} \
    --tag ${TAG} \
    --name "$(basename ${SRC_TOP}) ${TAG} pre release" \
    --description  < ${ARTIFACT_DIR}/buildnote.md
  rv=$?
  if [[ ${rv} -ne 0 ]];then
    github-release release \
      --user ${GITHUB_USER} \
      --repo ${GITHUB_REPO} \
      --tag ${TAG} \
      --name "$(basename ${SRC_TOP}) ${TAG} pre release" \
      --description < ${ARTIFACT_DIR}/buildnote.md
      --pre-release
  fi
}

case ${ACTION} in
    dev)
        do_docker_build
        do_compose_gen
        do_compose_test
        ;;
    pre)
        do_docker_build
        do_docker_push
        export USE_PUSHED_IMG=1
        do_compose_gen
        do_compose_test
        ;;
    release)
        echo "todo"
        ;;
    *)
        echo "unkown action"
        ;;
esac


