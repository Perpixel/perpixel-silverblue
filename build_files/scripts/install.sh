#!/usr/bin/bash

set -oex pipefail

# variables
#
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
ARCH=$(rpm -E '%_arch')

install_nvidia_container_toolkit() {
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
  dnf install nvidia-container-toolkit -y
}

build_initramfs() {
  # remove deprecated files
  rm -rf /usr/lib/dracut/dracut.conf.d/99-nvidia-dracut.conf
  # generate initramfs
  /usr/libexec/rpm-ostree/wrapped/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
  chmod 0600 /lib/modules/"${KERNEL_VERSION}"/initramfs.img
}

cleanup() {
  rm -rf /tmp/*
  rm -rf /var/*
  dnf -y clean all
}

install_packages() {
  "${BUILDROOT}"/scripts/packages.sh
}

# run installation

install_packages
source "$(dirname "$0")"/nvidia-installer.sh
depmod "${KERNEL_VERSION}"
#popd
install_nvidia_container_toolkit
build_initramfs
cleanup
