#!/bin/bash
set -oex pipefail

SPA_VERSION=0.2
PIPEWIRE_VERSION=$(rpm -q --queryformat '%{VERSION}' pipewire)
BUILT_DIR=/tmp/built

mkdir /tmp/pipewire
pushd /tmp/pipewire

# install build deps
dnf install -y meson gcc cmake glib2-devel dbus-devel sbc-devel bluez-libs-devel

# install libfreeaptx
git clone https://github.com/iamthehorker/libfreeaptx /tmp/pipewire/libfreeaptx
pushd /tmp/pipewire/libfreeaptx
make install PREFIX=/tmp/built/usr
popd

# export LIBRARY_PATH=/tmp/built/usr/lib64:${LIBRARY_PATH}
# export LD_LIBRARY_PATH=/tmp/built/usr/lib64:${LD_LIBRARY_PATH}
# export C_INCLUDE_PATH=/tmp/built/usr/include:${C_INCLUDE_PATH}
export PKG_CONFIG_PATH=/tmp/built/usr/lib/pkgconfig:${PKG_CONFIG_PATH}

# build bluez5-codec-aptx
rm -rf /tmp/pipewire/src
# get source
git clone --depth 1 --branch "${PIPEWIRE_VERSION}" https://gitlab.freedesktop.org/pipewire/pipewire.git /tmp/pipewire/src
pushd /tmp/pipewire/src

meson setup build
meson configure build -D bluez5-codec-aptx=enabled --auto-features=disabled \
  -D examples=disabled -D bluez5=enabled -D bluez5-codec-aptx=enabled \
  -D session-managers=[]
meson compile -C build spa-codec-bluez5-aptx
mkdir -p "${BUILT_DIR}"/usr/lib64/spa-"${SPA_VERSION}"/bluez5
install -pm 0755 ./build/spa/plugins/bluez5/libspa-codec-bluez5-aptx.so \
  "${BUILT_DIR}"/usr/lib64/spa-"${SPA_VERSION}"/bluez5/
popd
