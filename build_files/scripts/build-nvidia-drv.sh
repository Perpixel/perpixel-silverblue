#!/bin/sh

set -oeux pipefail

FEDORA_VERSION="$(rpm -E '%fedora')"
ARCH=$(rpm -E '%_arch')
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)

dnf install kernel-headers kernel-devel g++ kmod -y

if [ ${FEDORA_VERSION} == 40 ]; then
  ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld
fi

git clone --depth 1 --branch ${NVIDIA_VERSION} https://github.com/NVIDIA/open-gpu-kernel-modules /build/nvidia

# compile kernel modules
cd /build/nvidia
make modules -j$(nproc) KERNEL_UNAME="${KERNEL_VERSION}" SYSSRC="/usr/src/kernels/${KERNEL_VERSION}" IGNORE_CC_MISMATCH=1 IGNORE_XEN_PRESENCE=1 IGNORE_PREEMPT_RT_PRESENCE=1

mkdir -p /build/modules
cp /build/nvidia/kernel-open/nvidia*.ko /build/modules

rm -rf /build/nvidia
