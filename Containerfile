ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS builder

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

ARG AKMODS_CACHE="ghcr.io/perpixel/akmods-perpixel-silverblue"
ARG AKMODS_VERSION=${AKMODS_VERSION}

COPY --from=${AKMODS_CACHE}:${AKMODS_VERSION} / .

ADD build.sh /tmp/build.sh
ADD packages.json /tmp/packages.json
ADD post-install.sh /tmp/post-install.sh

RUN /tmp/build.sh
RUN /tmp/post-install.sh

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp