ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"

# Build NVIDIA drivers
#
# This will build the rpm from rpmfusion source and then make
# them available to the final image in this container.
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
COPY build_files /tmp/
RUN /tmp/scripts/build-nvidia-drv.sh
# End

# Build XONE kernel module
#
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as xone-builder
COPY build_files /tmp/
RUN /tmp/scripts/build-xone.sh
# End

# Build final image
#
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG AKMODS_IMAGE_NAME="${AKMODS_IMAGE_NAME}"
ARG AKMODS_VERSION="${AKMODS_VERSION}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"

COPY --from=nvidia-builder /var/cache /var/cache

COPY build_files /tmp/
COPY system_files / 
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub

RUN rpm-ostree cliwrap install-to-root / && \ 
  /tmp/scripts/install-rpmfusion.sh && \
  /tmp/scripts/install-xone.sh && \
  /tmp/scripts/install.sh

# Install Xbox dongle driver
COPY --from=xone-builder /var/xone/xow_dongle.bin /lib/firmware/xow_dongle.bin
COPY --from=xone-builder /var/xone /kernel/drivers/input/joystick/

RUN /tmp/scripts/cleanup.sh
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
