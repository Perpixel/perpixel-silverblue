#!/usr/bin/bash

set -oex pipefail

rpm-ostree cliwrap install-to-root /

# run installation
bash ${BUILDROOT}/scripts/packages.sh
