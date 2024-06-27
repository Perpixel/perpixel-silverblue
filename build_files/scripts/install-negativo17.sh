#!/bin/sh

set -ouex pipefail

# add negativo17 nvidia repo
wget -P /etc/yum.repos.d/ https://negativo17.org/repos/fedora-nvidia.repo
