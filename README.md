# perpixel-silverblue

[![build-all](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml/badge.svg)](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml)


Custom image of Fedora Silverblue for myself. Built for AMD hardware (amdgpu /
Mesa / ROCm), with the COSMIC desktop and a curated package set layered on top
of the upstream Silverblue base.

### Project Structure

-   `config.env`: Central configuration file for image build variables.
-   `Makefile`: Main entry point for building and managing the image.
-   `build.sh`: Wrapper script for `buildah` to build the image.
-   `Containerfile`: Container image definition (Dockerfile equivalent).
-   `build_files/`: Scripts used during the build.
-   `system_files/`: Files copied verbatim onto `/` in the image.

### Configuration

The project is configured via `config.env`:

-   `TARGET_IMAGE_NAME`: Name of the resulting image.
-   `BASE_IMAGE`: Upstream base image (Fedora Silverblue).
-   `FEDORA_VERSION`: Version of Fedora to use.

### Customization

To add or remove packages, edit the `dnf install` / `dnf remove` lists in
`build_files/scripts/packages.sh`.

### Rebase from ghcr.io

``` sh
rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/perpixel/<tag>
```

### Local build

``` sh
make container   # build the image locally
make rebase      # build and rebase onto the local image
```
