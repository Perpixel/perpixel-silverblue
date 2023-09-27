#!/bin/sh

set -ouex pipefail

# nvidia

NVIDIA_VERSION=535.113.01-1

rpm-ostree install \
    akmod-nvidia \
    nvidia-vaapi-driver
    #xorg-x11-drv-nvidia-{,cuda-,devel-,kmodsrc-,power-}${NVIDIA_VERSION}.fc${FEDORA_MAJOR_VERSION} \
    #nvidia-vaapi-driver \
    #akmod-nvidia-${NVIDIA_VERSION}.fc${FEDORA_MAJOR_VERSION} \
