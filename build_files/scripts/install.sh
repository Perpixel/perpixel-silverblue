#!/usr/bin/bash

set -ouex pipefail

# variables
#
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
FEDORA_VERSION="$(rpm -E '%fedora')"
ARCH=$(rpm -E '%_arch')

# setup fedora repos
#
mkdir -p /nvidia
cd /nvidia

# Install RPMs
rm -rf /etc/yum.repos.d/fedora-cisco-openh264.repo
rm -rf /etc/yum.repos.d/fedora-updates.repo
rm -rf /etc/yum.repos.d/fedora-updates-archive.repo
rm -rf /etc/yum.repos.d/fedora-updates-testing.repo

# define nvidia driver install process
#
install_nvidia_drivers() {

  mkdir -p /tmp/nvidia
  pushd /tmp/nvidia

  # download
  curl -O https://download.nvidia.com/XFree86/Linux-${ARCH}/${NVIDIA_VERSION}/NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run

  # extract
  sh ./NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run --extract-only --target nvidiapkg
  pushd ./nvidiapkg

  ./nvidia-installer -s \
    --no-kernel-modules \
    --x-library-path=/usr/lib64 \
    --no-systemd \
    --no-x-check \
    --no-check-for-alternate-installs \
    --skip-module-load \
    --skip-depmod \
    --no-rebuild-initramfs \
    --no-questions

  popd

  pushd /tmp/nvidia-modules
  mkdir -p /lib/modules/${KERNEL_VERSION}/kernel/drivers/video
  install -D -m 0755 nvidia*.ko /lib/modules/${KERNEL_VERSION}/kernel/drivers/video/
  depmod ${KERNEL_VERSION}
  popd
}

gen_initramfs() {
  # remove deprecated files
  rm -rf /usr/lib/dracut/dracut.conf.d/99-nvidia-dracut.conf
  # generate initramfs
  /usr/libexec/rpm-ostree/wrapped/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
  chmod 0600 /lib/modules/${KERNEL_VERSION}/initramfs.img
}

cleanup() {
  rm -rf /tmp/*
  rm -rf /var/*
}

# run installation
#
install_nvidia_drivers
gen_initramfs
cleanup

#. /tmp/scripts/packages.sh
#. /tmp/scripts/initramfs.sh
#. /tmp/scripts/post-install.sh
#. /tmp/scripts/cleanup.sh
