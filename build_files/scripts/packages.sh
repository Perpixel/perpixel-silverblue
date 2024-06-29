#!/bin/sh

set -ouex pipefail

INCLUDED_PACKAGES=(
binutils
#clang
distrobox
fd-find
ffmpeg
ffmpeg-libs
fswatch
#gcc
git
htop
ifuse
inxi
kitty
libtree-sitter
libva-utils
lld
#llvm
lm_sensors
material-icons-fonts
npm
#openh264
pipewire-codec-aptx
ripgrep
rclone
rpmconf
samba
SDL2
SDL2_mixer
SDL2_image
SDL2_net
tmux
vdpauinfo
xclip
zsh
plymouth-theme-spinfinity
)

EXCLUDED_PACKAGES=(
ffmpeg-free
libavcodec-free
libavdevice-free
libavfilter-free
libavformat-free
libavutil-free
libpostproc-free
libswresample-free
libswscale-free
mesa-va-drivers
firefox-langpacks
firefox
)

df -h

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

# nvidia

. /var/cache/akmods/nvidia-vars


NVIDIA_VERSION="555.58"

rpm-ostree install \
  /var/cache/x86_64/xorg-x11-drv-nvidia-cuda-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  /var/cache/x86_64/xorg-x11-drv-nvidia-cuda-libs-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/xorg-x11-drv-nvidia-devel-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/xorg-x11-drv-nvidia-kmodsrc-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/xorg-x11-drv-nvidia-libs-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/xorg-x11-drv-nvidia-power-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/xorg-x11-drv-nvidia-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/nvidia-modprobe-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/nvidia-settings-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/nvidia-xconfig-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
	/var/cache/x86_64/nvidia-persistenced-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  nvidia-vaapi-driver \
  nvtop \
  /var/cache/akmods/${NVIDIA_PACKAGE_NAME}/kmod-${NVIDIA_PACKAGE_NAME}-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${RELEASE}.rpm \
