#!/bin/bash

ARCH=$(rpm -E '%_arch')

_libdir=/usr/lib64
_datadir=/usr/share
_unitdir=/usr/lib/systemd/system
_systemd_util_dir=/usr/lib/systemd

if [ ! -d "nvidia_tmp" ]; then
  # download
  curl -O https://download.nvidia.com/XFree86/Linux-"${ARCH}"/"${NVIDIA_VERSION}"/NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run
  # extract
  sh ./NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run --extract-only --target nvidia_tmp
fi

dnf install -y xorg-x11-server-devel

pushd nvidia_tmp

./nvidia-installer -s \
  --no-kernel-modules \
  --x-library-path=${_libdir} \
  --no-x-check \
  --no-check-for-alternate-installs \
  --skip-module-load \
  --skip-depmod \
  --no-rebuild-initramfs \
  --glvnd-egl-config-path=${_libdir} \
  --no-questions \
  --no-systemd \
  --no-kernel-module-source \
  --no-dkms \
  --log-file-name=/tmp/nvidia-installer.log

cat /tmp/nvidia-installer.log

# EGL loader
install -p -m 0644 -D 10_nvidia.json ${_datadir}/glvnd/egl_vendor.d/10_nvidia.json
install -p -m 0644 -D *_nvidia_*.json ${_datadir}/glvnd/egl_vendor.d/

mkdir -p ${_unitdir}/
install -p -m 0644 systemd/system/*.service ${_unitdir}/
install -p -m 0755 -D systemd/system-sleep/nvidia ${_systemd_util_dir}/system-sleep/nvidia
install -p -m 0644 -D nvidia-dbus.conf ${_datadir}/dbus-1/system.d/nvidia-dbus.conf

systemctl enable nvidia-hibernate nvidia-resume nvidia-suspend
nvidia-xconfig --allow-empty-initial-configuration --no-sli --base-mosaic
ldconfig

# nvidia-persistenced
tar -xf nvidia-persistenced-init.tar.bz2
pushd nvidia-persistenced-init
install -p -m 0644 ./systemd/nvidia-persistenced.service.template ${_unitdir}/nvidia-persistenced.service
sed -i -e "s/__USER__/root/" ${_unitdir}/nvidia-persistenced.service
systemctl enable nvidia-persistenced
popd

popd

curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | tee /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf install nvidia-container-toolkit -y
# nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

exit 0
