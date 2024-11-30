#!/bin/sh

set -oex pipefail

source ./build_files/scripts/config.sh

podman pull ${BASE_IMAGE}:${FEDORA_VERSION}

buildah bud --pull=true \
  --tag=oci-archive:/tmp/${TARGET_IMAGE_NAME}.tar.gz \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg FEDORA_VERSION=${FEDORA_VERSION} \
  --build-arg NVIDIA_VERSION=${NVIDIA_VERSION} \
  --build-arg USE_LTS_KERNEL=${USE_LTS_KERNEL} \
  --no-cache \
  --pull=always \
  --volume $(pwd):/workspace:z \
  Containerfile
