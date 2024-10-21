#!/bin/sh

set -oex pipefail

export REPO="perpixel-silverblue"
export BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
export FEDORA_VERSION="41"
export NVIDIA_VERSION="560.35.03"
#export VERSION_TAG="local-${FEDORA_VERSION}-${NVIDIA_VERSION}"
#export TIMESTAMP="$(date +%Y%m%d)"

echo "Build system oci archive."

podman pull ${BASE_IMAGE}:${FEDORA_VERSION}

buildah bud --pull=true \
  --tag=oci-archive:/tmp/${REPO}.tar.gz \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg FEDORA_VERSION=${FEDORA_VERSION} \
  --build-arg NVIDIA_VERSION=${NVIDIA_VERSION} \
  --no-cache \
  --pull=always \
  --volume $(pwd):/workspace:z \
  Containerfile
