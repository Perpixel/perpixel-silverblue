#!/bin/sh

set -oeux pipefail

FEDORA_VERSION="$(rpm -E '%fedora')"
ARCH=$(rpm -E '%_arch')

mkdir -p /nvidia
cd /nvidia

# Install RPMs
rm -rf /etc/yum.repos.d/fedora-cisco-openh264.repo
rm -rf /etc/yum.repos.d/fedora-updates.repo
rm -rf /etc/yum.repos.d/fedora-updates-archive.repo
rm -rf /etc/yum.repos.d/fedora-updates-testing.repo
dnf install kernel-headers kernel-devel -y

# download
curl -O https://download.nvidia.com/XFree86/Linux-${ARCH}/${NVIDIA_VERSION}/NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run

# extract
sh ./NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run --extract-only --target nvidiapkg
cd ./nvidiapkg

# compile kernel modules
pushd kernel-open
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
make modules -j$(nproc) KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}" IGNORE_CC_MISMATCH=1 IGNORE_XEN_PRESENCE=1 IGNORE_PREEMPT_RT_PRESENCE=1
#make modules_install -j$(nproc) KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}"
popd
