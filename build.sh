#!/bin/sh

set -oex pipefail

# Resolve script directory to locate config.env
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CONFIG_FILE="${SCRIPT_DIR}/config.env"
NVIDIA_VERSION=$(./get_nvidia_versions.sh)

# Load configuration
if [ -f "${CONFIG_FILE}" ]; then
  set -a
  . "${CONFIG_FILE}"
  set +a
else
  echo "Error: config.env not found at ${CONFIG_FILE}."
  exit 1
fi

buildah pull ${BASE_IMAGE}:${FEDORA_VERSION}

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
