#!/bin/sh

set -ouex pipefail

INCLUDED_PACKAGES=(
bat
binutils
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
libtree-sitter
libva-utils
lld
lm_sensors
material-icons-fonts
npm
pipewire-codec-aptx
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
virtualbox-guest-additions
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

rpm-ostree install \
  /var/cache/nvidia-drv/xorg-x11-drv-nvidia-cuda-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  /var/cache/nvidia-drv/xorg-x11-drv-nvidia-cuda-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-devel-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-kmodsrc-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
 	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-xorg-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-power-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/xorg-x11-drv-nvidia-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/nvidia-modprobe-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/nvidia-settings-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/nvidia-xconfig-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
	/var/cache/nvidia-drv/nvidia-persistenced-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  nvidia-vaapi-driver \
  nvtop \
  /var/cache/akmods/${NVIDIA_PACKAGE_NAME}/kmod-${NVIDIA_PACKAGE_NAME}-${KERNEL_VERSION}-${NVIDIA_AKMOD_VERSION}.fc${RELEASE}.rpm \
