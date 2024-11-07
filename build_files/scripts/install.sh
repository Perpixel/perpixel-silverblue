#!/usr/bin/bash

set -oex pipefail

# variables
#
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)

rpm-ostree cliwrap install-to-root /
dnf install -y ansible

# run installation
ansible-playbook ${BUILDROOT}/playbooks/install-packages.ansible.yaml -e kernel_version=${KERNEL_VERSION} -e buildroot=${BUILDROOT}
depmod "${KERNEL_VERSION}"
