#!/bin/sh

while getopts "nps" opt; do
  case $opt in 
    p) PUSH_IMAGE=1;;
    s) BUILD_SYSTEM=1;;
    *) ;;
  esac
done

set -euxo pipefail

export REPO="perpixel-silverblue"
export BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="39"
export NVIDIA_MAJOR_VERSION="545"
export VERSION_TAG="local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}"
export TIMESTAMP="$(date +%Y%m%d)"

if [ "${BUILD_SYSTEM:-0}" -eq 1 ]; then
  echo "Build system oci archive."

  # tag for local oci archive
  #--tag oci-archive:/tmp/${NVIDIA_IMAGE_NAME}.tar.gz

  buildah bud \
    --tag ${NVIDIA_IMAGE_NAME}:${VERSION_TAG} \
    --tag ${NVIDIA_IMAGE_NAME}:${VERSION_TAG}-${TIMESTAMP} \
    --tag ${NVIDIA_IMAGE_NAME}:local \
    --tag ${NVIDIA_IMAGE_NAME}:latest \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    Containerfile.xone
fi

if [ "${PUSH_IMAGE:-0}" -eq 1 ]; then
  echo "Attempt to login on ghcr.io."
  echo "$(<pat.token )" | podman login ghcr.io -u gplourde@protonmail.com --password-stdin
  podman push localhost/${NVIDIA_IMAGE_NAME}:${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION} ghcr.io/perpixel/${NVIDIA_IMAGE_NAME}:${VERSION_TAG}
fi
