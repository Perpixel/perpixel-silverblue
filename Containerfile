ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as nvidia-builder

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf

ADD pre-install.sh /tmp/pre-install.sh
ADD build-nvidia-rpm.sh /tmp/build-nvidia-rpm.sh
ADD certs /tmp/certs

RUN /tmp/pre-install.sh
RUN /tmp/build-nvidia-rpm.sh

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} as xone-builder

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

RUN ln -s /usr/bin/rpm-ostree /usr/bin/dnf
ADD pre-install.sh /tmp/pre-install.sh
RUN /tmp/pre-install.sh
RUN rpm-ostree install dkms
# xone firmware
RUN git clone https://github.com/medusalix/xone
WORKDIR /xone
RUN ./install.sh --release

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG AKMODS_IMAGE_NAME="${AKMODS_IMAGE_NAME}"
ARG AKMODS_VERSION="${AKMODS_VERSION}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG NVIDIA_MAJOR_VERSION="${NVIDIA_MAJOR_VERSION}"

COPY --from=nvidia-builder /var/cache /var/cache

# config
ADD config/etc/containers /etc/ 
ADD cosign.pub /usr/etc/pki/containers/perpixel.pub

ADD pre-install.sh /tmp/pre-install.sh
ADD package-install.sh /tmp/package-install.sh
ADD post-install.sh /tmp/post-install.sh

RUN /tmp/pre-install.sh
RUN /tmp/package-install.sh
RUN /tmp/post-install.sh

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
