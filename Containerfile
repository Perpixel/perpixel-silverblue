ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

COPY pre-install.sh /tmp/pre-install.sh
COPY build-nvidia-rpm.sh /tmp/build-nvidia-rpm.sh
COPY certs /tmp/certs

RUN /tmp/pre-install.sh && /tmp/build-nvidia-rpm.sh

#######

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as xone-builder

WORKDIR /tmp

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

COPY build-xone.sh /tmp/build-xone.sh
COPY certs /tmp/certs

RUN /tmp/build-xone.sh

#######

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG AKMODS_IMAGE_NAME="${AKMODS_IMAGE_NAME}"
ARG AKMODS_VERSION="${AKMODS_VERSION}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

COPY --from=nvidia-builder /var/cache /var/cache

# config
COPY config/etc/containers /etc/ 
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub

COPY pre-install.sh /tmp/pre-install.sh
COPY package-install.sh /tmp/package-install.sh
COPY post-install.sh /tmp/post-install.sh

RUN /tmp/pre-install.sh && \
  /tmp/package-install.sh && \
  /tmp/post-install.sh

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
