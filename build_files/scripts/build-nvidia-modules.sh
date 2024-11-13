#!/bin/bash

set -oeux pipefail

ARCH="$(rpm -E '%_arch')"
# KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)

BUILT_DIR=/tmp/built

# Import external functions
source "$(dirname "$0")"/functions.sh

# Disable repos unwanted repos
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
# disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

mkdir -p /tmp/nvidia
pushd /tmp/nvidia

# Install build requirements
# Getting kernel source from Koji in order to avoid build failure when silverblue image kernel is outdated
# dnf install koji g++ kmod patch -y
# koji download-build --arch="${ARCH}" kernel-"${KERNEL_VERSION}"
# dnf install -y kernel-devel-*.rpm
# rm -rf /tmp/nvidia/*.rpm

# longterm kernel https://copr.fedorainfracloud.org/coprs/kwizart/kernel-longterm-6.6/
FEDORA_VERSION=41
curl -s -L https://copr.fedorainfracloud.org/coprs/kwizart/kernel-longterm-6.6/repo/fedora-${FEDORA_VERSION}/kwizart-kernel-longterm-6.6-fedora-${FEDORA_VERSION}.repo |
  tee /etc/yum.repos.d/kwizart-kernel-longterm-6.6-fedora-${FEDORA_VERSION}.repo
dnf install -y g++ kmod patch kernel-longterm-devel
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-longterm-devel)

# Making sure ld is available on fedora 40
ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld

# Clone open NVIDIA kernel modules from Github
git clone --depth 1 --branch "${NVIDIA_VERSION}" https://github.com/NVIDIA/open-gpu-kernel-modules /tmp/nvidia/src

# Build kernel modules
pushd /tmp/nvidia/src
ln -s kernel-open kernel

# Kernel patchs
# patch -p1 <"${BUILDROOT}"/patchs/nvidia/make_modeset_default.patch

# Build
make modules -j"$(nproc)" KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}" IGNORE_CC_MISMATCH=1 IGNORE_XEN_PRESENCE=1 IGNORE_PREEMPT_RT_PRESENCE=1

# Copy modules

mkdir -p "${BUILT_DIR}"/usr/lib/modules/"${KERNEL_VERSION}"/kernel/drivers/video
install -D -m 0755 ./kernel/nvidia*.ko ${BUILT_DIR}/usr/lib/modules/"${KERNEL_VERSION}"/kernel/drivers/video/
popd
popd
rm -rf /tmp/nvidia
