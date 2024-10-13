#!/usr/bin/bash

set -oex pipefail

source "$(dirname "$0")"/functions.sh

# variables
#
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
ARCH=$(rpm -E '%_arch')

# define nvidia driver install process
#
install_nvidia_drivers() {

  mkdir -p /tmp/nvidia
  pushd /tmp/nvidia

  # download
  curl -O https://download.nvidia.com/XFree86/Linux-"${ARCH}"/"${NVIDIA_VERSION}"/NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run
  # extract
  sh ./NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run --extract-only --target nvidiapkg
  # install driver files
  pushd ./nvidiapkg
  ./nvidia-installer -s \
    --no-kernel-modules \
    --x-library-path=/usr/lib64 \
    --no-x-check \
    --no-check-for-alternate-installs \
    --skip-module-load \
    --skip-depmod \
    --no-rebuild-initramfs \
    --glvnd-egl-config-path=/usr/lib64 \
    --no-questions \
    --log-file-name=/tmp/nvidia-installer.log

  cat /tmp/nvidia-installer.log

  nvidia-xconfig --allow-empty-initial-configuration --no-sli --base-mosaic

  mkdir -p /usr/lib/systemd/system-{sleep,preset}

  # Systemd units and script for suspending/resuming
  printf '%s\n' 'enable nvidia-hibernate.service' \
    'enable nvidia-resume.service' \
    'enable nvidia-suspend.service' \
    'enable nvidia-powerd.service' >/usr/lib/systemd/system-preset/70-nvidia.preset
  chmod 0644 /usr/lib/systemd/system-preset/70-nvidia.preset

  install -p -m 0644 systemd/system/nvidia-{hibernate,powerd,resume,suspend}.service /usr/lib/systemd/system/

  # Install dbus config
  # install    -m 0755 -d               %{buildroot}%{_dbus_systemd_dir}
  install -p -m 0644 nvidia-dbus.conf /usr/share/dbus-1/system.d/
  # Ignore powerd binary exiting if hardware is not present
  # We should check for information in the DMI table
  sed -i -e 's/ExecStart=/ExecStart=-/g' /usr/lib/systemd/system/nvidia-powerd.service
  install -p -m 0755 systemd/system-sleep/nvidia /usr/lib/systemd/system-sleep
  install -p -m 0755 systemd/nvidia-sleep.sh /usr/bin/

  popd
  # install open kernel modules
  pushd /tmp/nvidia-modules
  mkdir -p /lib/modules/"${KERNEL_VERSION}"/kernel/drivers/video
  install -D -m 0755 nvidia*.ko /lib/modules/"${KERNEL_VERSION}"/kernel/drivers/video/
  depmod "${KERNEL_VERSION}"
  popd
}

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
}

install_packages() {
  /tmp/scripts/packages.sh
}

# run installation

install_packages
install_nvidia_drivers
install_nvidia_container_toolkit
build_initramfs
cleanup

#. /tmp/scripts/packages.sh
