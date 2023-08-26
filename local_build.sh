#!/bin/sh

while getopts "np" opt; do
  case $opt in 
    n) BUILD_AKMODS=1;;
    p) PUSH=1;;
  esac
done
  
export REPO="perpixel-silverblue"
export AKMODS_IMAGE_NAME="akmods-${REPO}"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="38"
export NVIDIA_MAJOR_VERSION="535"
export LOCAL_VERSION="local"

if [ ${PUSH:-0} -eq 1 ]; then
  echo "Attempt to login on ghcr.io."
  echo "$(<pat.token )" | podman login ghcr.io -u gplourde@protonmail.com --password-stdin
fi 

if [ ${BUILD_AKMODS:-0} -eq 1 ]; then
  echo "Build nvidia akmods rpm."
  export IMAGE_NAME=${AKMODS_IMAGE_NAME}
  podman build \
    --file Containerfile.nvi \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --tag ${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

  if [ ${PUSH:-0} -eq 1]; then
    podman push localhost/${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${AKMODS_IMAGE_NAME}:${LOCAL_VERSION}
  fi
fi 

export IMAGE_NAME=${NVIDIA_IMAGE_NAME}
podman build \
    --file Containerfile.sys \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --build-arg AKMODS_VERSION=${LOCAL_VERSION} \
    --tag ${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

if [ ${PUSH:-0} -eq 1 ]; then
  podman push localhost/${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${NVIDIA_IMAGE_NAME}:${LOCAL_VERSION}
fi
