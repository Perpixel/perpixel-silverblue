#!/bin/bash

FEDORA_VERSION=41
IMAGE=quay.io/fedora-ostree-desktops/silverblue:${FEDORA_VERSION}

podman pull ${IMAGE}
podman run -it --rm -v ./build_files/scripts:/tmp/scripts ${IMAGE} /tmp/scripts/packages.sh
