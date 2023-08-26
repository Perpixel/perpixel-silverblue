#!/bin/sh

set -ouex pipefail

# TODO: do I need this?
ln -s /usr/bin/ld.bfd /etc/alternatives/ld
ln -s /etc/alternatives/ld /usr/bin/ld

# vs code
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
rpm-ostree install code

# proton bridge 
wget -P /tmp/rpms https://proton.me/download/bridge/protonmail-bridge-3.3.2-1.x86_64.rpm
rpm-ostree install /tmp/rpms/protonmail-bridge*rpm
