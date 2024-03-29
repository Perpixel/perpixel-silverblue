#!/bin/sh

set -ouex pipefail

# TODO: do I need this?
ln -s /usr/bin/ld.bfd /etc/alternatives/ld
ln -s /etc/alternatives/ld /usr/bin/ld

# Proton mail
wget -nv -P /tmp/rpms https://proton.me/download/bridge/protonmail-bridge-3.6.1-2.x86_64.rpm
rpm-ostree install /tmp/rpms/protonmail-bridge*rpm

# nvidia-container-toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
rpm-ostree install -y nvidia-container-toolkit