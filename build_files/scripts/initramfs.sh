#!/usr/bin/bash

set -oue pipefail

# remove deprecated files
rm -rf /usr/lib/dracut/dracut.conf.d/99-nvidia-dracut.conf

# generate initramfs
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
/usr/libexec/rpm-ostree/wrapped/dracut --no-hostonly --kver "${KERNEL_VERSION}" --reproducible -v --add ostree -f "/lib/modules/${KERNEL_VERSION}/initramfs.img"
chmod 0600 /lib/modules/${KERNEL_VERSION}/initramfs.img
