#!/bin/sh

set -ouex pipefail

# download and install rpm fusion package
wget -P /tmp/rpms \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm

rpm-ostree install /tmp/rpms/*.rpm fedora-repos-archive

#sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# enable
sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/fedora-cisco-openh264.repo

# disable
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-updates-testing.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
