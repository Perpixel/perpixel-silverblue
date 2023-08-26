#!/bin/sh

set -ouex pipefail

#RELEASE="$(rpm -E %fedora)"

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-{cisco-openh264,modular,updates-modular}.repo

rpm-ostree install wget

wget -P /tmp/rpms \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm

rpm-ostree install \
    /tmp/rpms/*.rpm \
    fedora-repos-archive

