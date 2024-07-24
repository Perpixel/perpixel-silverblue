#!/bin/sh

set -ouex pipefail

# Proton mail
# wget -nv -P /tmp/rpms https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm
# rpm-ostree install /tmp/rpms/ProtonMail-*.rpm

# nvidia-container-toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
rpm-ostree install -y nvidia-container-toolkit
