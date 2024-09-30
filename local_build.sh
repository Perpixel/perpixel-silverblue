#!/bin/sh

export REPO="perpixel-silverblue"
export BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="41"
export NVIDIA_VERSION="560.35.03"
export VERSION_TAG="local-${FEDORA_MAJOR_VERSION}-${NVIDIA_VERSION}"
export TIMESTAMP="$(date +%Y%m%d)"

echo "Build system oci archive."

# tag for local oci archive
#--tag oci-archive:/tmp/${NVIDIA_IMAGE_NAME}.tar.gz

#  buildah pull ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

buildah bud --pull=true \
  --tag ${NVIDIA_IMAGE_NAME}:${VERSION_TAG} \
  --tag ${NVIDIA_IMAGE_NAME}:${VERSION_TAG}-${TIMESTAMP} \
  --tag ${NVIDIA_IMAGE_NAME}:local \
  --tag ${NVIDIA_IMAGE_NAME}:latest \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
  --build-arg NVIDIA_VERSION=${NVIDIA_VERSION} \
  Containerfile

mkdir -p ./archives
podman save --format oci-archive ${NVIDIA_IMAGE_NAME}:${VERSION_TAG} -o ./archives/${NVIDIA_IMAGE_NAME}_${VERSION_TAG}
