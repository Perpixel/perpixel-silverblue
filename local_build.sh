#!/bin/sh

#export REPO="perpixel-silverblue"
export BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
export TARGET_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_VERSION="41"
export NVIDIA_VERSION="560.35.03"
#export VERSION_TAG="local-${FEDORA_VERSION}-${NVIDIA_VERSION}"
#export TIMESTAMP="$(date +%Y%m%d)"

echo "Build system oci archive."

podman pull ${BASE_IMAGE}:${FEDORA_VERSION}

buildah bud --pull=true \
  --tag oci-archive:/tmp/${TARGET_IMAGE_NAME}.tar.gz \
  --build-arg TARGET_IMAGE_NAME=${TARGET_IMAGE_NAME} \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg FEDORA_VERSION=${FEDORA_VERSION} \
  --build-arg NVIDIA_VERSION=${NVIDIA_VERSION} \
  Containerfile
