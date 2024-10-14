ARG TARGET_IMAGE_NAME="${TARGET_IMAGE_NAME}"
ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_VERSION="${FEDORA_VERSION}"

# Collect current packages

FROM ghcr.io/perpixel/${TARGET_IMAGE_NAME}:${FEDORA_VERSION} as packages-list
RUN rpm -qa >/packages.old

# Build NVIDIA drivers
#
# This will build the rpm from rpmfusion source and then make
# them available to the final image in this container.i

FROM ${BASE_IMAGE}:${FEDORA_VERSION} as nvidia-builder
RUN NVIDIA_VERSION=$(<nvidia-version.txt)
COPY build_files/scripts /tmp/scripts
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/build-nvidia-drv.sh

# Build final image
#

FROM ${BASE_IMAGE}:${FEDORA_VERSION}
RUN NVIDIA_VERSION=$(<nvidia-version.txt)
COPY build_files/scripts /tmp/scripts
COPY --from=nvidia-builder /build/modules /tmp/nvidia-modules
COPY --from=packages-list /packages.old /tmp/build/packages.old
COPY system_files / 
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/install.sh \
  && ostree container commit \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
