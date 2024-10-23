#!/bin/bash

ARCH=$(rpm -E '%_arch')

_libdir=/usr/lib64
_datadir=/usr/share
_target_cpu=x86_64
_bindir=/usr/bin
_sysconfdir=/etc
_modprobedir=/lib/modprobe.d
_unitdir=/usr/lib/systemd/system
_systemd_util_dir=/usr/lib/systemd
_udevrulesdir=/usr/lib/udev/rules.d

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

# X stuff
mkdir -p ${_sysconfdir}/X11/xorg.conf.d
printf '%s\n' \
  'Section "OutputClass"' \
  '    Identifier "nvidia"' \
  '    MatchDriver "nvidia-drm"' \
  '    Driver "nvidia"' \
  '    Option "AllowEmptyInitialConfiguration"' \
  '    Option "SLI" "Auto"' \
  '    Option "BaseMosaic" "on"' \
  'EndSection' \
  >${_sysconfdir}/X11/xorg.conf.d/10-nvidia.conf

# TODO:  this doesn't seems to work?
printf '%s\n' \
  'enable nvidia-hibernate.service' \
  'enable nvidia-resume.service' \
  'enable nvidia-suspend.service' \
  '# enable nvidia-powerd.service' \
  >${_systemd_util_dir}/system-preset/70-nvidia-driver.preset
chmod 0644 ${_systemd_util_dir}/system-preset/70-nvidia-driver.preset

printf 'enable nvidia-persistenced.service\n' \
  >${_systemd_util_dir}/system-preset/70-nvidia-driver-cuda.preset
chmod 0644 ${_systemd_util_dir}/system-preset/70-nvidia-driver-cuda.preset

mkdir -p ${_unitdir}/
install -p -m 0644 systemd/system/*.service ${_unitdir}/
install -p -m 0755 -D systemd/system-sleep/nvidia ${_systemd_util_dir}/system-sleep/nvidia
install -p -m 0644 -D nvidia-dbus.conf ${_datadir}/dbus-1/system.d/nvidia-dbus.conf

systemctl enable nvidia-hibernate nvidia-resume nvidia-suspend
nvidia-xconfig --allow-empty-initial-configuration --no-sli --base-mosaic
ldconfig

# printf '%s\n' \
#   '# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind' \
#   'ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"' \
#   'ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"' \
#   '# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind' \
#   'ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"' \
#   'ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"' \
#   >${_udevrulesdir}/80-nvidia-pm.rules
# chmod 0644 ${_udevrulesdir}/80-nvidia-pm.rules

# nvidia-persistenced

tar -xf nvidia-persistenced-init.tar.bz2
pushd nvidia-persistenced-init
install -p -m 0644 ./systemd/nvidia-persistenced.service.template ${_unitdir}/nvidia-persistenced.service
sed -i -e "s/__USER__/root/" ${_unitdir}/nvidia-persistenced.service
systemctl enable nvidia-persistenced
popd

popd
