#!/bin/sh

while getopts "nps" opt; do
  case $opt in 
    n) BUILD_AKMODS=1;;
    s) BUILD_SYSTEM=1;;
    *) ;;
  esac
done
  
export REPO="perpixel-silverblue"
export BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
export AKMODS_IMAGE_NAME="akmods-${REPO}"
export NVIDIA_IMAGE_NAME="nvidia-${REPO}"
export FEDORA_MAJOR_VERSION="39"
export NVIDIA_MAJOR_VERSION="535"
export VERSION_TAG="local-${FEDORA_MAJOR_VERSION}-${NVIDIA_MAJOR_VERSION}"

if [ "${BUILD_AKMODS:-0}" -eq 1 ]; then
  echo "Build nvidia akmods rpm."
  buildah bud \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --tag ${AKMODS_IMAGE_NAME}:${VERSION_TAG} \
    --tag ${AKMODS_IMAGE_NAME}:local \
    Containerfile.nvi
fi 

if [ "${BUILD_SYSTEM:-0}" -eq 1 ]; then
  echo "Build system oci archive."

  # tag for local oci archive
  #--tag oci-archive:/tmp/${NVIDIA_IMAGE_NAME}.tar.gz

  buildah bud \
    --tag ${NVIDIA_IMAGE_NAME}:${VERSION_TAG} \
    --tag ${NVIDIA_IMAGE_NAME}:local \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg FEDORA_MAJOR_VERSION=${FEDORA_MAJOR_VERSION} \
    --build-arg NVIDIA_MAJOR_VERSION=${NVIDIA_MAJOR_VERSION} \
    --build-arg AKMODS_VERSION=${VERSION_TAG} \
    --build-arg AKMODS_IMAGE_NAME="${AKMODS_IMAGE_NAME}" \
    Containerfile.sys
fi
