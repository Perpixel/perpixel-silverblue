ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/silverblue"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS builder

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

ADD nvidia-build.sh /tmp/nvidia-build.sh
ADD certs /tmp/certs

RUN /tmp/nvidia-build.sh

FROM scratch

COPY --from=builder /var/cache /var/cache