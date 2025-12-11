# perpixel-silverblue

[![build-all](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml/badge.svg)](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml)


Custom image of Fedora Silverblue for myself. Nvidia drivers built from source.

### Project Structure

-   `config.env`: Central configuration file for image build variables.
-   `Makefile`: Main entry point for building and managing the image.
-   `build.sh`: Wrapper script for `buildah` to build the image.
-   `Containerfile`: Container image definition (Dockerfile equivalent).
-   `build_files/`: Scripts and playbooks used during the build.

### Configuration

The project is configured via `config.env`. You can modify the following variables:

-   `TARGET_IMAGE_NAME`: Name of the resulting image.
-   `BASE_IMAGE`: Upstream base image (e.g., Fedora Silverblue).
-   `FEDORA_VERSION`: Version of Fedora to use.
-   `USE_LTS_KERNEL`: Set to `true` to use the LTS kernel from COPR.
-   `NVIDIA_VERSION`: Specific NVIDIA driver version to build.

### Customization

To add or remove packages, edit:
`build_files/playbooks/install-packages.ansible.yaml`

### Rebase from ghcr.io

``` sh
rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/perpixel/<tag>
```

### Local build

``` sh
make build
# Then rebase:
make rebase
```

### Kernel args

``` sh
sudo rpm-ostree kargs --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau
```
