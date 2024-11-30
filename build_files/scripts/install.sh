#!/usr/bin/bash

set -oex pipefail

rpm-ostree cliwrap install-to-root /
dnf install -y ansible

# run installation
ansible-playbook ${BUILDROOT}/playbooks/install-packages.ansible.yaml \
  --extra-vars "kernel_longterm=${USE_LTS_KERNEL} buildroot=${BUILDROOT} fedora_version=${FEDORA_VERSION}"
