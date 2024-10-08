#!/bin/sh

set -ouex pipefail

INCLUDED_PACKAGES=(
  bat
  binutils
  clang
  cmake
  distrobox
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
  lld
  lm_sensors
  make
  material-icons-fonts
  npm
  nvidia-vaapi-driver
  nvtop
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
        ${INCLUDED_PACKAGES[@]}

elif [[ ${#INCLUDED_PACKAGES[@]} -eq 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]}

elif [[ ${#INCLUDED_PACKAGES[@]} -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove \
        ${EXCLUDED_PACKAGES[@]} \
        $(printf -- "--install=%s " ${INCLUDED_PACKAGES[@]})

else
    echo "No packages to install."
fi
