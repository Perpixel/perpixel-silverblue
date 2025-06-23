# perpixel-silverblue

[![build-all](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml/badge.svg)](https://github.com/perpixel/perpixel-silverblue/actions/workflows/build-all.yml)


Custom image of Fedora Silverblue for myself. Nvidia drivers built from source.

### Rebase from ghcr.io

``` sh
rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/perpixel/<tag>
```

### Local build

``` sh
local_build.sh && rpm-ostree rebase ostree-unverified-image:oci-archive:/tmp/...
```

### Kernel args

``` sh
sudo rpm-ostree kargs --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau
```
