#!/bin/bash

set -ouex pipefail

FEDORA_VERSION="$(rpm -E '%fedora')"

# Install RPMs

function disable-repo() {
  sed -i 's/enabled=1/enabled=0/' "${1}"
}

function enable-repo() {
  sed -i 's/enabled=0/enabled=1/' "${1}"
}

rpm-ostree cliwrap install-to-root /

# download and install rpm fusion package
wget -P /tmp/rpms \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${FEDORA_VERSION}".noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${FEDORA_VERSION}".noarch.rpm

# disable
disable-repo /etc/yum.repos.d/fedora-cisco-openh264.repo
#sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-updates.repo
disable-repo /etc/yum.repos.d/fedora-updates-testing.repo
disable-repo /etc/yum.repos.d/fedora-updates-archive.repo

dnf install /tmp/rpms/rpmfusion*.rpm -y

sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/rpmfusion-free-updates.repo
disable-repo /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
disable-repo /etc/yum.repos.d/rpmfusion-free-updates-testing.repo

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
  EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

if [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
  rpm-ostree install \
    "${INCLUDED_PACKAGES[@]}"

elif [[ "${#INCLUDED_PACKAGES[@]}" -eq 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}"

elif [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  rpm-ostree override remove \
    "${EXCLUDED_PACKAGES[@]}" \
    $(printf -- "--install=%s " "${INCLUDED_PACKAGES[@]}")

else
  echo "No packages to install."
fi
