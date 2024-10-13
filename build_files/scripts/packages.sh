#!/bin/bash

set -ouex pipefail

FEDORA_VERSION="$(rpm -E '%fedora')"
source "$(dirname "$0")"/functions.sh

INCLUDED_PACKAGES=(
  bat
  binutils
  clang
  cmake
  distrobox
  egl-x11
  egl-gbm
  egl-utils
  egl-wayland
  libglvnd-egl
  libwayland-egl
  fd-find
  ffmpeg
  ffmpeg-libs
  fswatch
  fzf
  git
  gnome-session-xsession
  htop
  ifuse
  inxi
  kitty
  kmod
  libva-utils
  libtree-sitter
  lld
  lm_sensors
  make
  material-icons-fonts
  npm
  nvidia-vaapi-driver
  nvtop
  opencl-filesystem
  pipewire-codec-aptx
  plymouth-theme-spinfinity
  ripgrep
  rclone
  rpmconf
  samba
  SDL2
  SDL2_mixer
  SDL2_image
  SDL2_net
  stow
  tmux
  vdpauinfo
  xclip
  zsh
)

EXCLUDED_PACKAGES=(
  libavdevice-free
  libavcodec-free
  libavfilter-free
  libavformat-free
  libavutil-free
  libpostproc-free
  libswresample-free
  libswscale-free
  ffmpeg-free
  mesa-va-drivers
  firefox-langpacks
  firefox
  virtualbox-guest-additions
)

if [[ ${#EXCLUDED_PACKAGES[@]} -gt 0 ]]; then
  mapfile -t EXCLUDED_PACKAGES < <(rpm -qa --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}")
fi

# Install RPMs

rpm-ostree cliwrap install-to-root /

# download and install rpm fusion package
wget -P /tmp/rpms \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm

# disable
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

dnf install /tmp/rpms/rpmfusion*.rpm -y

disable-repo /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
disable-repo /etc/yum.repos.d/rpmfusion-free-updates-testing.repo

if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
  rpm-ostree install \
    "${INCLUDED_PACKAGES[@]}"

elif [[ "${#INCLUDED_PACKAGES[@]}" -eq 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}"

elif [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}" \
    $(printf -- '--install=%s ' "${INCLUDED_PACKAGES[@]}")

else
  echo "No packages to install."
fi

if [ -f /tmp/changelist.txt ]; then
  rpm -qa >/tmp/packages.new
  diff /tmp/packages.old /tmp/packages.new >/tmp/changelist.txt
  cat /tmp/changelist.txt
fi
