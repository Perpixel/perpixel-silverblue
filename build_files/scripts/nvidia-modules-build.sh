#!/bin/bash

set -oeux pipefail

ARCH="$(rpm -E '%_arch')"
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)

# Import external functions
source "$(dirname "$0")"/functions.sh

# Disable repos unwanted repos
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

# Install build requirements
# Getting kernel source from Koji in order to avoid build failure when silverblue image kernel is outdated
dnf install koji g++ kmod patch -y
koji download-build --arch="${ARCH}" kernel-"${KERNEL_VERSION}"
dnf install -y kernel-devel-*.rpm
rm -rf kernel*.rpm

# Making sure ld is available on fedora 40
ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld

# Clone open NVIDIA kernel modules from Github
git clone --depth 1 --branch "${NVIDIA_VERSION}" https://github.com/NVIDIA/open-gpu-kernel-modules /build/nvidia

# Build kernel modules
cd /build/nvidia
ln -s kernel-open kernel

# Kernel patchs
# patch -p1 <"${BUILDROOT}"/patchs/nvidia/make_modeset_default.patch

# Build
make modules -j"$(nproc)" KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}" IGNORE_CC_MISMATCH=1 IGNORE_XEN_PRESENCE=1 IGNORE_PREEMPT_RT_PRESENCE=1

# Copy modules
mkdir -p /tmp/nvidia/modules
cp /build/nvidia/kernel-open/nvidia*.ko /tmp/nvidia/modules
rm -rf /build/nvidia
