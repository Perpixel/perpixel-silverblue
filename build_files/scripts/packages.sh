#!/bin/bash

set -ouex pipefail

FEDORA_VERSION="$(rpm -E '%fedora')"

INCLUDED_PACKAGES=(
  autoconf
  automake
  bat
  binutils
  bison
  bootc
  distrobox
  clang
  cmake
  gettext
  hwinfo
  libtool
  lld
  fd-find
  fswatch
  fzf
  git
  gnome-session-xsession
  htop
  ifuse
  inxi
  kitty
  libva-utils
  libtree-sitter
  lm_sensors
  make
  material-icons-fonts
  npm
  nvidia-vaapi-driver
  nvtop
  opencl-filesystem
  plymouth-theme-spinfinity
  ripgrep
  rclone
  samba
  SDL2
  SDL2_mixer
  SDL2_image
  SDL2_net
  stow
  vdpauinfo
  xclip
  zsh
)

EXCLUDED_PACKAGES=(
  mesa-va-drivers
  firefox-langpacks
  firefox
  virtualbox-guest-additions
)

rpm-ostree cliwrap install-to-root /
source "$(dirname "$0")"/functions.sh

# Disable unwanted Fedora repos
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

# Keep only package currently installed in the EXCLUDE list
if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
  mapfile -t EXCLUDED_PACKAGES < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}")
fi

# Download and install rpm fusion package
# wget -P /tmp/rpms \
#   https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
#   https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm

# Install RPMFusion
# dnf install /tmp/rpms/rpmfusion*.rpm -y
# disable-repo /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
# disable-repo /etc/yum.repos.d/rpmfusion-free-updates-testing.repo

# Just install INCLUDED if EXCLUDED is empty
if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
  rpm-ostree install \
    "${INCLUDED_PACKAGES[@]}"

# Just remove unwanted packaged if the include list is empty
elif [[ "${#INCLUDED_PACKAGES[@]}" -eq 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}"

# Install and remove packages
elif [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then

  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}" \
    $(printf -- '--install=%s ' "${INCLUDED_PACKAGES[@]}")
else
  echo "No packages to process..."
fi
