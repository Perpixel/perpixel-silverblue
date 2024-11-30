#!/bin/bash

source ./build_files/scripts/config.sh

while [[ $# -gt 0 ]]; do
  case $1 in
  --all)
    TEST_ALL=true
    shift
    ;;
  --nvidia)
    TEST_NVIDIA=true
    shift
    ;;
  --packages)
    TEST_PACKAGES=true
    shift
    ;;
  --pipewire)
    TEST_PIPEWIRE=true
    shift
    ;;
  esac
done

podman pull ${IMAGE}

if [ "${TEST_NVIDIA}" == true ] || [ "${TEST_ALL}" == true ]; then
  podman run -it --rm -e NVIDIA_VERSION="${NVIDIA_VERSION}" -e USE_LTS_KERNEL="${USE_LTS_KERNEL}" -e BUILDROOT="/build" -v ./build_files/:/build ${BASE_IMAGE}:${FEDORA_VERSION} /build/scripts/build-nvidia-modules.sh
fi

if [ "${TEST_PACKAGES}" == true ] || [ "${TEST_ALL}" == true ]; then
  podman run -it --rm -e BUILDROOT="/build" -v ./build_files/:/build ${IMAGE} /build/scripts/packages.sh
fi

if [ "${TEST_PIPEWIRE}" == true ] || [ "${TEST_ALL}" == true ]; then
  podman run -it --rm -e BUILDROOT="/build" -v ./build_files/:/build ${IMAGE} /build/scripts/build-pipewire-aptx.sh
fi
