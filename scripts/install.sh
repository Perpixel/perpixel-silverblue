#!/usr/bin/bash
# shellcheck disable=SC1091

set -ouex pipefail

# . /tmp/build/copr-repos.sh
# . /tmp/build/install-akmods.sh
. /tmp/scripts/packages.sh
. /tmp/scripts/nvidia.sh
# . /tmp/build/image-info.sh
# . /tmp/build/fetch-install.sh
# . /tmp/build/fetch-quadlets.sh
# . /tmp/build/font-install.sh
# . /tmp/build/systemd.sh
# . /tmp/build/bluefin-changes.sh
# . /tmp/build/aurora-changes.sh
# . /tmp/build/branding.sh
. /tmp/scripts/initramfs.sh
. /tmp/scripts/post-install.sh
# . /tmp/build/cleanup.sh
