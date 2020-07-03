#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
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
  export DOCKER_HOST=
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

readonly REPO_NAME=$(basename ${SRC_TOP})
readonly DOCKERFILE_DIR=$(dirname "$(realpath "${DOCKERFILE}")" | tr '[A-Z]' '[a-z]')
readonly DOCKERFILE_NAME=$(basename ${DOCKERFILE} | tr '[A-Z]' '[a-z]')
readonly IMG_TMP=$(echo "${REPO_NAME}-${DOCKERFILE_NAME}" | tr '[A-Z]' '[a-z]')
readonly ARTIFACT_DIR="${SRC_TOP}/dist/${DOCKERFILE_NAME}"

readonly SRC_VERSION=$(head -n 1 ${SRC_TOP}/VERSION)
readonly SRC_SHA=-$(git rev-parse --short HEAD)
readonly OS_DIST=$(echo ${DOCKERFILE_NAME} |cut -d. -f2)

function do_docker_build() {

  docker build . --file ${DOCKERFILE} --tag ${IMG_TMP}
  mkdir -p ${ARTIFACT_DIR}
  set +e
  cid=$(docker create ${IMG_TMP})
  docker cp $cid:/.buildnote.md ${ARTIFACT_DIR}/buildnote.md
  docker cp $cid:/.s2erunner  ${ARTIFACT_DIR}/s2erunner
  docker rm -v $cid

  echo "> Docker image size: $(($(docker inspect ${IMG_TMP} --format='{{.Size}}')/1000/1000))MB" | tee -a ${ARTIFACT_DIR}/buildnote.md

  echo -e "\n\n" >> ${ARTIFACT_DIR}/buildnote.md
  cat ${ARTIFACT_DIR}/s2erunner/.tpl/*.md >>  ${ARTIFACT_DIR}/buildnote.md
  echo "\n\n" >> ${ARTIFACT_DIR}/buildnote.md
  set -e

  cat ${ARTIFACT_DIR}/buildnote.md
}

function do_validate_ci_version() {
  # Accept things like "v1.2.3-alpha.4.56+abcdef12345678" or "v1.2.3-beta.4"
  local -r version_regex="^v(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)-([a-zA-Z0-9]+)\\.(0|[1-9][0-9]*)(\\.(0|[1-9][0-9]*)\\+[0-9a-f]{7,40})?$"
  local -r version="${1-}"
  [[ "${version}" =~ ${version_regex} ]] || {
    echo "Invalid ci version: '${version}', must match regex ${version_regex}"
    return 1
  }

  # The VERSION variables are used when this file is sourced, hence
  # the shellcheck SC2034 'appears unused' warning is to be ignored.

  # shellcheck disable=SC2034
  VERSION_MAJOR="${BASH_REMATCH[1]}"
  # shellcheck disable=SC2034
  VERSION_MINOR="${BASH_REMATCH[2]}"
  # shellcheck disable=SC2034
  VERSION_PATCH="${BASH_REMATCH[3]}"
  # shellcheck disable=SC2034
  VERSION_PRERELEASE="${BASH_REMATCH[4]}"
  # shellcheck disable=SC2034
  VERSION_PRERELEASE_REV="${BASH_REMATCH[5]}"
  # shellcheck disable=SC2034
  VERSION_BUILD_INFO="${BASH_REMATCH[6]}"
  # shellcheck disable=SC2034
  VERSION_COMMITS="${BASH_REMATCH[7]}"
}

function do_docker_push() {
  readonly DOCKER_HOST=${DOCKER_HOST:-registry-1.docker.io}
  readonly DOCKER_NS=${DOCKER_NS:-bettercode}
  readonly DOCKER_IMG=${REPO_NAME}
  readonly DOCKER_USER=${DOCKER_USER:-bettercode}
  readonly DOCKER_PASS=${DOCKER_PASS}

  if [[ -n ${DOCKER_PASS} ]];then
    docker login -u "${DOCKER_USER}" -p  "${DOCKER_PASS}" ${DOCKER_HOST}/${DOCKER_NS}


    readonly IMAGE_URL=$(echo ${DOCKER_HOST}/${DOCKER_NS}/${DOCKER_IMG}| tr '[A-Z]' '[a-z]')
    readonly DOCKER_TAG=${SRC_VERSION}-${OS_DIST}-${SRC_SHA}
    echo IMAGE_URL=$IMAGE_URL
    echo DOCKER_TAG=$DOCKER_TAG

    docker tag ${IMG_TMP} $IMAGE_URL:${DOCKER_TAG}
    docker tag ${IMG_TMP} $IMAGE_URL:latest
    docker push $IMAGE_URL:${DOCKER_TAG}
    docker push $IMAGE_URL:latest
    echo $IMAGE_URL:${DOCKER_TAG} | tee -a ${ARTIFACT_DIR}/img.txt

    set +e
    docker rmi ${IMG_TMP}
    docker rmi $IMAGE_URL:${DOCKER_TAG}
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
  echo "Using Docker Image: ${IMG}"
  /bin/ls --color ${ARTIFACT_DIR}/*
  /bin/cp -f ${ARTIFACT_DIR}/s2erunner/.tpl/docker-compose.yaml ${ARTIFACT_DIR}/s2erunner/docker-compose.yaml
  cat ${ARTIFACT_DIR}/s2erunner/.tpl/*.md >> ${ARTIFACT_DIR}/buildnote.md
  perl -ni -e "s@^([# ]+image:).+@\1 ${IMG}@g;print" ${ARTIFACT_DIR}/s2erunner/docker-compose.yaml
  cd ${ARTIFACT_DIR}/s2erunner/
  docker-compose config
}

do_compose_test() {
  cd ${ARTIFACT_DIR}/s2erunner
  docker-compose config
  docker-compose up --force-recreate -d
  sleep 20
  docker-compose ps
  docker-compose exec -T runner ps aux
  docker-compose down
  docker-compose rm -f
}

do_release() {
  local GITHUB_USER=${GITHUB_USER:-chimeh}
  local GITHUB_REPO=${GITHUB_REPO:-${REPO_NAME}}

  CUR_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
  if [[ ! "${CUR_BRANCH_NAME}" ="release" ]];then
    # branch name not contain `release`, error.
    echo "branch name not contain keyword 'release', error."
    exit 1
  fi
  BRANCH_MARJOR_MINOR=$(echo ${CUR_BRANCH_NAME} |  perl -ne '$_ =~ /\b((0|[1-9][0-9]*).(0|[1-9][0-9]*))/;print $1' -)
  SRC_MARJOR_MINOR=$(echo ${SRC_VERSION} |  perl -ne '$_ =~ /\b((0|[1-9][0-9]*).(0|[1-9][0-9]*))/;print $1' -)

  if [[ "${BRANCH_MARJOR_MINOR}" =~ "${SRC_MARJOR_MINOR}" ]];then

  else
    echo " error. Marjor.Minor should be equal, ${BRANCH_MARJOR_MINOR} on branch name ${CUR_BRANCH_NAME} via ${SRC_MARJOR_MINOR} on src."
    exit 1
  fi
  # word 'alpha' 'beta' appear on branch name or commit message, assume that release
  if [[ "${CUR_BRANCH_NAME}" =~ "alpha" ]];then
    PRERELEASE_TYPE='alpha'
  elif [[ "${CUR_BRANCH_NAME}" =~ "beta" ]];then
    PRERELEASE_TYPE='beta'
  else
    PRERELEASE_TYPE='alpha'
  fi

  if [[ -z ${GITHUB_TOKEN} ]];then
      echo "GITHUB_TOKEN not set ,exit!"
      exit 1
  fi
  if ! command -v github-release; then
      echo "github-release cli not found!"
      go get github.com/github-release/github-release
  fi

  RELEASE_TITLE="${SRC_VERSION} ${PRERELEASE_TYPE} release"
 github-release edit \
    --user ${GITHUB_USER} \
    --repo ${GITHUB_REPO} \
    --tag ${SRC_VERSION} \
    --name "${RELEASE_TITLE}" \
    --description  < ${ARTIFACT_DIR}/buildnote.md
  rv=$?
  if [[ ${rv} -ne 0 ]];then
    github-release release \
      --user ${GITHUB_USER} \
      --repo ${GITHUB_REPO} \
      --tag ${TAG} \
      --name "${RELEASE_TITLE}" \
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
    *)
        echo "unkown action"
        ;;
esac


