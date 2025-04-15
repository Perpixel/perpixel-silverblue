#!/bin/bash

set -oeux pipefail

ARCH="$(rpm -E '%_arch')"
BUILT_DIR=/tmp/built
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)

# Import external functions
source "$(dirname "$0")"/functions.sh

# Disable repos unwanted repos
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
# disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

mkdir -p /tmp/nvidia
cd /tmp/nvidia

if [ ${USE_LTS_KERNEL} = true ]; then
  source "$(dirname "$0")"/kernel-installer.sh --devel
  KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-longterm-devel)
else
  # Install build requirements
  # Getting kernel source from Koji in order to avoid build failure when silverblue image kernel is outdated
  dnf install koji gcc-c++ kmod patch -y
  koji download-build --arch="${ARCH}" kernel-"${KERNEL_VERSION}"
  dnf install -y kernel-devel-*.rpm
  rm -rf /tmp/nvidia/*.rpm
fi

# Clone open NVIDIA kernel modules from Github
git clone --depth 1 --branch "${NVIDIA_VERSION}" https://github.com/NVIDIA/open-gpu-kernel-modules /tmp/nvidia/src

# Build kernel modules
cd /tmp/nvidia/src
ln -s kernel-open kernel

# Kernel patchs
# patch -p1 <"${BUILDROOT}"/patchs/nvidia/make_modeset_default.patch
# patch -p1 <"${BUILDROOT}"/patchs/nvidia/8ac26d3c66ea88b0f80504bdd1e907658b41609d.patch

# Build
export CC="gcc -std=gnu17"
make modules -j"$(nproc)" KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}" IGNORE_CC_MISMATCH=1 IGNORE_XEN_PRESENCE=1 IGNORE_PREEMPT_RT_PRESENCE=1

# Copy modules

mkdir -p "${BUILT_DIR}"/nvidia/"${KERNEL_VERSION}"
install -D -m 0755 ./kernel/nvidia*.ko ${BUILT_DIR}/nvidia/"${KERNEL_VERSION}"
ls -la ${BUILT_DIR}/nvidia/"${KERNEL_VERSION}"
cd /
rm -rf /tmp/nvidia
