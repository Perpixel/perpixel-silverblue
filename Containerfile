ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"

# Run a rpm package install test to fail early when missing dependecies
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/install.sh test-packages

# Build NVIDIA drivers
#
# This will build the rpm from rpmfusion source and then make
# them available to the final image in this container.i

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
COPY build_files /tmp/
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/build-nvidia-drv.sh

# Build final image
#
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
COPY build_files /tmp/
COPY --from=nvidia-builder /build/modules /tmp/nvidia-modules
COPY build_files /tmp/
COPY system_files / 
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/install.sh \
  && ostree container commit \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
