#!/bin/sh

set -ouex pipefail

# Proton mail
wget -nv -P /tmp/rpms https://proton.me/download/bridge/protonmail-bridge-3.3.2-1.x86_64.rpm
rpm-ostree install /tmp/rpms/protonmail-bridge*rpm
