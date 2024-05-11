ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

COPY scripts /tmp/scripts
COPY certs /tmp/certs

RUN /tmp/scripts/install-rpmfusion.sh && /tmp/scripts/build-nvidia-rpm.sh

#######

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as xone-builder

WORKDIR /tmp

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

COPY scripts /tmp/scripts
COPY certs /tmp/certs

RUN /tmp/scripts/build-xone.sh

#######

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG AKMODS_IMAGE_NAME="${AKMODS_IMAGE_NAME}"
ARG AKMODS_VERSION="${AKMODS_VERSION}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

COPY --from=nvidia-builder /var/cache /var/cache

COPY scripts /tmp/scripts
COPY certs /tmp/certs
COPY system_files / 

RUN rm -rf /usr/lib/dracut/dracut.conf.d/99-nvidia-dracut.conf

COPY cosign.pub /usr/etc/pki/containers/perpixel.pub

RUN rpm-ostree cliwrap install-to-root / && \ 
  /tmp/scripts/install-rpmfusion.sh && \
  /tmp/scripts/install.sh

# Install Xbox dongle driver
COPY --from=xone-builder /var/xone/xow_dongle.bin /lib/firmware/xow_dongle.bin
RUN echo -e "\
  blacklist xpad\n\
  blacklist mt76x2u\
  " > /etc/modprobe.d/xone-blacklist.conf

COPY --from=xone-builder /var/xone /kernel/drivers/input/joystick/

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
