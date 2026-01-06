#!/bin/bash

set -ouex pipefail

# Variables
WITH_NVIDIA=true

# 1. Install longterm kernel
if [[ "${USE_LTS_KERNEL}" == "true" ]]; then
  bash "${BUILDROOT}/scripts/kernel-installer.sh"
  KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-longterm)
else
  # Get kernel version from standard kernel
  KERNEL_VERSION=$(ls /usr/lib/modules/ | head -n 1)
fi

# 2. Install Nvidia kernel modules
if [[ "${WITH_NVIDIA}" == "true" ]]; then
  echo "Installing Nvidia kernel modules for ${KERNEL_VERSION}..."
  mkdir -p "/usr/lib/modules/${KERNEL_VERSION}/kernel/drivers/video/"
  cp /tmp/builder/nvidia/"${KERNEL_VERSION}"/*.ko "/usr/lib/modules/${KERNEL_VERSION}/kernel/drivers/video/"
  depmod "${KERNEL_VERSION}"
fi

# 3. Install RPM Fusion repo
dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# 4. Install new packages
dnf install -y \
  bootc \
  distrobox \
  hwinfo \
  fswatch \
  fzf \
  ifuse \
  inxi \
  kitty \
  libva-nvidia-driver \
  libva-utils \
  libtree-sitter \
  lm_sensors \
  material-icons-fonts \
  opencl-filesystem \
  ripgrep \
  steam \
  stow \
  xclip \
  zsh

dnf install -y \
  cosmic-app-library \
  cosmic-applets \
  cosmic-bg \
  cosmic-comp \
  cosmic-config-fedora \
  cosmic-edit \
  cosmic-files \
  cosmic-greeter \
  cosmic-icon-theme \
  cosmic-idle \
  cosmic-initial-setup \
  cosmic-launcher \
  cosmic-notifications \
  cosmic-osd \
  cosmic-panel \
  cosmic-player \
  cosmic-randr \
  cosmic-screenshot \
  cosmic-session \
  cosmic-store \
  cosmic-wallpapers \
  cosmic-settings \
  cosmic-settings-daemon \
  cosmic-term \
  cosmic-workspaces

# 5. Install development packages
dnf install -y \
  binutils \
  cmake \
  cpp \
  gcc \
  g++ \
  git \
  glibc-devel \
  libstdc++-devel \
  make \
  patch

# 6. Remove packages
dnf remove -y \
  firefox \
  firefox-langpacks \
  virtualbox-guest-additions

# 7. Install Nvidia drivers
if [[ "${WITH_NVIDIA}" == "true" ]]; then
  bash "${BUILDROOT}/scripts/nvidia-installer.sh"
fi

# 8. Cleanup
rm -rf /tmp/*
rm -rf /var/*
dnf -y clean all
