#!/bin/bash

set -ouex pipefail

# 1. Install RPM Fusion repo
dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# 2. Install new packages
dnf install -y \
  bootc \
  distrobox \
  hwinfo \
  fswatch \
  fzf \
  ifuse \
  inxi \
  kitty \
  libva-utils \
  libtree-sitter \
  lm_sensors \
  material-icons-fonts \
  mesa-va-drivers-freeworld \
  opencl-filesystem \
  radeontop \
  ripgrep \
  steam \
  stow \
  vdpauinfo \
  vulkan-tools \
  xclip \
  zsh

# 32-bit (multilib) graphics drivers for Steam / Proton gaming
dnf install -y \
  mesa-dri-drivers.i686 \
  mesa-vulkan-drivers.i686 \
  mesa-libGL.i686 \
  mesa-libEGL.i686

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

# Ghostty
# dnf5 copr enable scottames/ghostty
# dnf install ghostty

# 3. Install development packages
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
  patch \
  rocm

# 4. Remove packages
dnf remove -y \
  firefox \
  firefox-langpacks \
  virtualbox-guest-additions

# 5. Cleanup
rm -rf /tmp/*
rm -rf /var/*
dnf -y clean all
