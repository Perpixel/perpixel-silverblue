#!/bin/sh

set -oeux pipefail

RELEASE="$(rpm -E '%fedora.%_arch')"

NVIDIA_PACKAGE_NAME="nvidia"

mkdir -p /tmp/nvidia-drv
cd /tmp/nvidia-drv

# dnf update 4.21 beak akmods build
rpm-ostree install yum-4.19.* python3-dnf-plugin-versionlock
yum versionlock dnf-4.19
yum versionlock dnf-4.19.*
yum versionlock dnf-data-4.19.*

wget https://github.com/Perpixel/nvidia-driver-rpms/releases/download/v${NVIDIA_VERSION}/nvidia-drv-${NVIDIA_VERSION}.tar.gz
tar -zxf nvidia-drv-*.tar.gz

rpm-ostree install \
  ./akmod-nvidia-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-cuda-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-cuda-libs-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-devel-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-kmodsrc-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-libs-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-power-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./kmod-nvidia-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./nvidia-modprobe-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./nvidia-settings-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./nvidia-xconfig-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./nvidia-persistenced-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  mock

# alternatives cannot create symlinks on its own during a container build
ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld

if [[ ! -s "/tmp/certs/private_key.priv" ]]; then
  echo "WARNING: Using test signing key. Run './generate-akmods-key' for production builds."
  cp /tmp/certs/private_key.priv{.test,}
  cp /tmp/certs/public_key.der{.test,}
fi

install -Dm644 /tmp/certs/public_key.der /etc/pki/akmods/certs/public_key.der
install -Dm644 /tmp/certs/private_key.priv /etc/pki/akmods/private/private_key.priv

# Either successfully build and install the kernel modules, or fail early with debug output
KERNEL_VERSION="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
NVIDIA_AKMOD_VERSION="$(basename "$(rpm -q "akmod-${NVIDIA_PACKAGE_NAME}" --queryformat '%{VERSION}-%{RELEASE}')" ".fc${RELEASE%%.*}")"
NVIDIA_LIB_VERSION="$(basename "$(rpm -q "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}" --queryformat '%{VERSION}-%{RELEASE}')" ".fc${RELEASE%%.*}")"
NVIDIA_FULL_VERSION="$(rpm -q "xorg-x11-drv-${NVIDIA_PACKAGE_NAME}" --queryformat '%{EPOCH}:%{VERSION}-%{RELEASE}.%{ARCH}')"

akmods --force --kernels "${KERNEL_VERSION}" --kmod "${NVIDIA_PACKAGE_NAME}"

modinfo /usr/lib/modules/${KERNEL_VERSION}/extra/${NVIDIA_PACKAGE_NAME}/nvidia{,-drm,-modeset,-peermem,-uvm}.ko.xz >/dev/null ||
  (cat /var/cache/akmods/${NVIDIA_PACKAGE_NAME}/${NVIDIA_AKMOD_VERSION}-for-${KERNEL_VERSION}.failed.log && exit 1)

mv /tmp/nvidia-drv /var/cache/

cat <<EOF >/var/cache/akmods/nvidia-vars
KERNEL_VERSION=${KERNEL_VERSION}
RELEASE=${RELEASE}
NVIDIA_PACKAGE_NAME=${NVIDIA_PACKAGE_NAME}
NVIDIA_VERSION=${NVIDIA_VERSION}
NVIDIA_FULL_VERSION=${NVIDIA_FULL_VERSION}
NVIDIA_AKMOD_VERSION=${NVIDIA_AKMOD_VERSION}
NVIDIA_LIB_VERSION=${NVIDIA_LIB_VERSION}
EOF
