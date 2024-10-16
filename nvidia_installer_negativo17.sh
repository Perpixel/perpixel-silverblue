#!/bin/bash

VERSION=560.35.03
KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel)
ARCH=$(rpm -E '%_arch')

_libdir=/usr/lib64
_datadir=/usr/share
_target_cpu=x86_64
_bindir=/usr/bin
_sysconfdir=/etc
_modprobedir=/lib/modprobe.d
_unitdir=/usr/lib/systemd
_systemd_util_dir=/usr/lib/systemd

if [ ! -d "nvidia_tmp" ]; then
  # download
  curl -O https://download.nvidia.com/XFree86/Linux-"${ARCH}"/"${VERSION}"/NVIDIA-Linux-"${ARCH}"-"${VERSION}".run
  # extract
  sh ./NVIDIA-Linux-"${ARCH}"-"${VERSION}".run --extract-only --target nvidia_tmp
fi

pushd nvidia_tmp

# EGL loader
install -p -m 0644 -D 10_nvidia.json ${_datadir}/glvnd/egl_vendor.d/10_nvidia.json

# Vulkan loader
install -p -m 0644 -D nvidia_icd.json ${_datadir}/vulkan/icd.d/nvidia_icd.${_target_cpu}.json
sed -i -e "s|libGLX_nvidia|${_libdir}/libGLX_nvidia|g" ${_datadir}/vulkan/icd.d/nvidia_icd.${_target_cpu}.json

# Vulkan SC loader and compiler
install -p -m 0644 -D nvidia_icd_vksc.json ${_datadir}/vulkansc/icd.d/nvidia_icd.${_target_cpu}.json
sed -i -e "s|libnvidia-vksc-core|${_libdir}/libnvidia-vksc-core|g" ${_datadir}/vulkansc/icd.d/nvidia_icd.${_target_cpu}.json
install -p -m 0755 -D nvidia-pcc ${_bindir}/nvidia-pcc

# Unique libraries
mkdir -p ${_libdir}/vdpau/
cp -a lib*GL*_nvidia.so* libcuda*.so* libnv*.so* ${_libdir}/
cp -a libvdpau_nvidia.so* ${_libdir}/vdpau/

# GBM loader
mkdir -p ${_libdir}/gbm/
ln -sf ../libnvidia-allocator.so.${VERSION} ${_libdir}/gbm/nvidia-drm_gbm.so

# NGX Proton/Wine library
mkdir -p ${_libdir}/nvidia/wine/
cp -a *.dll ${_libdir}/nvidia/wine/

# Empty?
mkdir -p ${_sysconfdir}/nvidia/

# OpenCL config
install -p -m 0755 -D nvidia.icd ${_sysconfdir}/OpenCL/vendors/nvidia.icd

# Binaries
mkdir -p ${_bindir}
install -p -m 0755 nvidia-{debugdump,smi,cuda-mps-control,cuda-mps-server,bug-report.sh,ngx-updater,powerd,xconfig} ${_bindir}

# Man pages
install -p -m 0644 nvidia-{smi,cuda-mps-control}*.gz /usr/share/man/man1/

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

install -p -m 0755 -D nvidia_drv.so ${_libdir}/xorg/modules/drivers/nvidia_drv.so
install -p -m 0755 -D libglxserver_nvidia.so.${VERSION} ${_libdir}/xorg/modules/extensions/libglxserver_nvidia.so

# NVIDIA specific configuration files
mkdir -p ${_datadir}/nvidia/
install -p -m 0644 nvidia-application-profiles-${VERSION}-key-documentation \
  ${_datadir}/nvidia/
install -p -m 0644 nvidia-application-profiles-${VERSION}-rc \
  ${_datadir}/nvidia/

# OptiX
install -p -m 0644 nvoptix.bin ${_datadir}/nvidia/

# Systemd units and script for suspending/resuming
mkdir -p ${_systemd_util_dir}/system-preset/

printf '%s\n' \
  'enable nvidia-hibernate.service' \
  'enable nvidia-resume.service' \
  'enable nvidia-suspend.service' \
  'enable nvidia-powerd.service' \
  >${_systemd_util_dir}/system-preset/70-nvidia-driver.preset
chmod 0644 ${_systemd_util_dir}/system-preset/70-nvidia-driver.preset

printf 'enable nvidia-persistenced.service\n' \
  >${_systemd_util_dir}/system-preset/70-nvidia-driver-cuda.preset
chmod 0644 ${_systemd_util_dir}/system-preset/70-nvidia-driver-cuda.preset

mkdir -p ${_unitdir}/
install -p -m 0644 systemd/system/*.service ${_unitdir}/
install -p -m 0755 systemd/nvidia-sleep.sh ${_bindir}/
install -p -m 0755 -D systemd/system-sleep/nvidia ${_systemd_util_dir}/system-sleep/nvidia
install -p -m 0644 -D nvidia-dbus.conf ${_datadir}/dbus-1/system.d/nvidia-dbus.conf

# Ignore powerd binary exiting if hardware is not present
# We should check for information in the DMI table
sed -i -e 's/ExecStart=/ExecStart=-/g' ${_unitdir}/nvidia-powerd.service

# Vulkan layer
install -p -m 0644 -D nvidia_layers.json ${_datadir}/vulkan/implicit_layer.d/nvidia_layers.json

# install AppData and add modalias provides
#install -p -m 0644 -D %{SOURCE40} %{buildroot}%{_metainfodir}/com.nvidia.driver.metainfo.xml
#%{SOURCE41} supported-gpus/supported-gpus.json | xargs appstream-util add-provide %{buildroot}%{_metainfodir}/com.nvidia.driver.metainfo.xml modalias
mkdir -p ${_datadir}/pixmaps/
cp nvidia-settings.png ${_datadir}/pixmaps/

nvidia-xconfig --allow-empty-initial-configuration --no-sli --base-mosaic

popd
