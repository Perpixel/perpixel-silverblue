#!/usr/bin/bash

set -ouex pipefail

cd /tmp/nvidia
nvidia_installer() {
  printf "Run NVIDIA driver installer..."
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
}

nvidia_installer

cd ./kernel-open
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
mkdir -p /lib/modules/${KERNEL_VERSION}/extra/nvidia
install -D -m 0755 nvidia*.ko /lib/modules/${KERNEL_VERSION}/extra/nvidia/

rm -rf /usr/lib/dracut/dracut.conf.d/99-nvidia-dracut.conf
