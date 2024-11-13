#!/usr/bin/bash

set -oex pipefail

rpm-ostree cliwrap install-to-root /
dnf install -y ansible

# run installation
ansible-playbook ${BUILDROOT}/playbooks/install-packages.ansible.yaml -e buildroot=${BUILDROOT} -e fedora_version=${FEDORA_VERSION}
