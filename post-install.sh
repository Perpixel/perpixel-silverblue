#!/bin/sh

set -ouex pipefail

# TODO: do I need this?
ln -s /usr/bin/ld.bfd /etc/alternatives/ld
ln -s /etc/alternatives/ld /usr/bin/ld

# Proton mail
wget -nv -P /tmp/rpms https://proton.me/download/bridge/protonmail-bridge-3.3.2-1.x86_64.rpm
rpm-ostree install /tmp/rpms/protonmail-bridge*rpm
