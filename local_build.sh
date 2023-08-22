#!/bin/sh

export REPO="perpixel-silverblue"
export AKMODS_IMAGE_NAME="akmods-${REPO}"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="38"
export NVIDIA_MAJOR_VERSION="535"
export LOCAL_VERSION="local"

echo "$(<pat.token )" | podman login ghcr.io -u gplourde@protonmail.com --password-stdin

export IMAGE_NAME=${AKMODS_IMAGE_NAME}

podman build \
    --file nvidia.Containerfile \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --tag ${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

podman push localhost/${AKMODS_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${AKMODS_IMAGE_NAME}:${LOCAL_VERSION}

export IMAGE_NAME=${NVIDIA_IMAGE_NAME}

podman build \
    --file Containerfile \
    --build-arg IMAGE_NAME=${AKMODS_IMAGE_NAME} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --build-arg AKMODS_VERSION=${LOCAL_VERSION} \
    --tag ${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}

podman push localhost/${NVIDIA_IMAGE_NAME}:local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${NVIDIA_IMAGE_NAME}:${LOCAL_VERSION}