#!/bin/bash

FEDORA_VERSION=41
IMAGE=quay.io/fedora-ostree-desktops/silverblue:${FEDORA_VERSION}

while [[ $# -gt 0 ]]; do
  case $1 in
  --all)
    TEST_NVIDIA=true
    TEST_PACKAGES=true
    shift
    ;;
  --test-nvidia)
    TEST_NVIDIA=true
    shift
    ;;
  --test-packages)
    TEST_PACKAGES=true
    shift
    ;;
  esac
done

podman pull ${IMAGE}

if [ "${TEST_NVIDIA}" == true ]; then
  podman run -it --rm -v ./build_files/scripts:/tmp/scripts ${IMAGE} /tmp/scripts/build-nvidia-drv.sh
fi

if [ "${TEST_PACKAGES}" == true ]; then
  podman run -it --rm -v ./build_files/scripts:/tmp/scripts ${IMAGE} /tmp/scripts/packages.sh
fi
