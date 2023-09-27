#!/bin/sh

set -ouex pipefail

INCLUDED_PACKAGES=(
alacritty
ansible
distrobox
emacs
fd-find
ffmpeg
ffmpeg-libs
ffmpegthumbnailer
flac
git
gnome-tweaks
htop
ifuse
irssi
kitty
libmad
libavcodec-freeworld
libva-utils
libvorbis
lm_sensors
material-icons-fonts
mesa-va-drivers-freeworld
neovim
npm
nvtop
openh264
pipewire-codec-aptx
qemu
ripgrep
rclone
samba
SDL2
tmux
vdpauinfo
virt-viewer
VirtualBox
zsh
)

EXCLUDED_PACKAGES=(
libavcodec-free
libavdevice-free
libavfilter-free
libavformat-free
libavutil-free
libpostproc-free
libswresample-free
libswscale-free
libva-vdpau-driver
mesa-va-drivers
vi
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

# nvidia

NVIDIA_VERSION=535.113.01-1

rpm-ostree install \
    xorg-x11-drv-nvidia-{,cuda-,devel-,kmodsrc-,power-}${NVIDIA_VERSION}.fc${FEDORA_MAJOR_VERSION} \
    nvidia-vaapi-driver \
    akmod-nvidia-${NVIDIA_VERSION}.fc${FEDORA_MAJOR_VERSION} \
