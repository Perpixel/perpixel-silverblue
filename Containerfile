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
#RUN /tmp/pre-install.sh
RUN rpm-ostree install cabextract lld dkms
# xone firmware
RUN ln -s /usr/bin/lld /usr/bin/ld
WORKDIR /tmp
RUN git clone https://github.com/medusalix/xone
WORKDIR /tmp/xone
RUN make -C /lib/modules/`uname -r`/build M=$PWD
RUN mkdir /var/xone
RUN cp *.ko /var/xone/
WORKDIR /var/xone
RUN curl -L -o driver.cab http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/07/1cd6a87c-623f-4407-a52d-c31be49e925c_e19f60808bdcbfbd3c3df6be3e71ffc52e43261e.cab
RUN cabextract -F FW_ACC_00U.bin driver.cab


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

# Install Xbox dongle driver
COPY --from=xone-builder /var/xone/FW_ACC_00U.bin /lib/firmware/xow_dongle.bin
RUN echo -e "\
blacklist xpad\n\
blacklist mt76x2u\
" > /etc/modprobe.d/xone-blacklist.conf

COPY --from=xone-builder /var/xone /kernel/drivers/input/joystick/

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN mkdir -p /var/tmp && chmod -R 1777 /var/tmp
