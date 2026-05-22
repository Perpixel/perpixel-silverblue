# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A custom Fedora Silverblue OCI image (bootc/ostree). The build layers extra packages, the COSMIC desktop, and hardware tweaks onto the upstream `fedora-ostree-desktops/silverblue` base, then publishes it to `ghcr.io/perpixel/perpixel-silverblue`. End users `rpm-ostree rebase` / `bootc switch` onto the published image — there is no application code, only build orchestration and system config.

## Commands

```sh
make container   # build the image locally via build.sh -> oci-archive:/tmp/perpixel-silverblue.tar.gz
make rebase      # bootc switch onto the freshly built local archive
make update      # bootc update to the latest local image
make clean       # remove the /tmp tarball
```

There is no test suite or linter. "Building" means producing the container image; validation is done by booting into it. The local build (`build.sh`) shells out to `buildah bud` with `--no-cache`, so a full build is slow and downloads the whole base image.

## Build flow

1. `config.env` is the single source of truth for build variables (`TARGET_IMAGE_NAME`, `BASE_IMAGE`, `FEDORA_VERSION`). It is sourced by `Makefile`, `build.sh`, and the GitHub workflow alike — change values here, not in the consumers.
2. `Containerfile` runs `build_files/scripts/install.sh`, which calls `packages.sh`. **`packages.sh` is where almost all real customization lives** — package installs/removals, RPM Fusion setup, kernel selection. To add/remove packages, edit the `dnf install`/`dnf remove` lists there (the README points at an Ansible playbook that no longer exists).
3. `system_files/` is copied verbatim onto `/` in the image. These are drop-in config files (systemd units, `/etc/environment`, etc.).

## Hardware target: AMD

This image targets AMD GPUs using the in-tree `amdgpu` driver — there are no out-of-tree kernel modules to build. VA-API video decode comes from RPM Fusion's `mesa-va-drivers-freeworld` (carries the codecs the stock Fedora package strips); `rocm` provides compute; `/etc/environment` sets `LIBVA_DRIVER_NAME=radeonsi`. For Steam/Proton, `packages.sh` also installs the 32-bit (`.i686`) Mesa DRI/Vulkan/GL drivers. Note F44 RPM Fusion has no `mesa-vdpau-drivers-freeworld` — VA-API is the only freeworld video path. (This repo was previously NVIDIA-based with source-built drivers; that machinery — `get_nvidia_versions.sh`, the builder stage, `nvidia-installer.sh`, `kernel-installer.sh`, the LTS-kernel option — has all been removed.)

`build-pipewire-aptx.sh` is orphaned (not called by any script).

## CI

`.github/workflows/build-all.yml` is the entry point (PRs, weekly cron, manual dispatch). It calls `build-system.yml` (buildah build + push to GHCR; injects `config.env` into the env) then `cleanup.yml` (prunes old GHCR images). PRs get `pr-<n>` tags; pushes get `<fedora-version>` and dated tags. CI does an aggressive disk cleanup step first because the base image is large.
