#!/bin/sh

while getopts ":a:p:" opt; do
  case $opt in 
    n) BUILD_AKMODS=true
    ;;
    p) PUSH=true
  esac
done
  
export REPO="perpixel-silverblue"
export AKMODS_IMAGE_NAME="akmods-${REPO}"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="38"
export NVIDIA_MAJOR_VERSION="535"
export LOCAL_VERSION="local"

if [$PUSH -eq true]; then
  echo "$(<pat.token )" | podman login ghcr.io -u gplourde@protonmail.com --password-stdin
fi 

if [ $BUILD_AKMODS -eq true ]; then
  export IMAGE_NAME=${AKMODS_IMAGE_NAME}
  podman build \
    --file nvidia.Containerfile \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --tag ${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

  if [$PUSH -eq true]; then
    podman push localhost/${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${AKMODS_IMAGE_NAME}:${LOCAL_VERSION}
  fi
fi 

export IMAGE_NAME=${NVIDIA_IMAGE_NAME}
podman build \
    --file Containerfile \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --build-arg AKMODS_VERSION=${LOCAL_VERSION} \
    --tag ${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

if [$PUSH -eq true]; then
  podman push localhost/${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${NVIDIA_IMAGE_NAME}:${LOCAL_VERSION}
fi