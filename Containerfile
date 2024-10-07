ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"

# Build NVIDIA drivers
#
# This will build the rpm from rpmfusion source and then make
# them available to the final image in this container.
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
COPY build_files /tmp/
RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/build-nvidia-drv.sh

# End

# Build final image
#
#
FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

RUN rm -rf /etc/yum.repos.d/fedora-cisco-openh264.repo \
  && rm -rf /etc/yum.repos.d/fedora-updates.repo \
  && rm -rf /etc/yum.repos.d/fedora-updates-archive.repo \
  && rm -rf /etc/yum.repos.d/fedora-updates-testing.repo

COPY --from=nvidia-builder /nvidia/nvidiapkg /tmp/nvidia

COPY build_files /tmp/
COPY system_files / 
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub

RUN rpm-ostree cliwrap install-to-root / \
  && /tmp/scripts/install.sh \
  && /tmp/scripts/cleanup.sh \
  && ostree container commit \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
