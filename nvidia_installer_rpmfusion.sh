VERSION=560.35.03
KERNEL_VERSION=$(rpm -q --queryformat '${VERSION}-%{RELEASE}.%{ARCH}' kernel)
ARCH=$(rpm -E '%_arch')
LIBDIR=/usr/lib64
DATADIR=/usr/share
BINDIR=/usr/bin
SYSCONFDIR=/etc
MODPROBEDIR=/lib/modprobe.d

# download
curl -O https://download.nvidia.com/XFree86/Linux-"${ARCH}"/"${NVIDIA_VERSION}"/NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run

# extract
sh ./NVIDIA-Linux-"${ARCH}"-"${NVIDIA_VERSION}".run --extract-only --target nvidiapkg
cd nvidiapkg

# Install only required libraries
mkdir -p ${LBIDIR}

cp -a \
  libcuda.so.${VERSION} \
  libEGL_nvidia.so.${VERSION} \
  libGLESv1_CM_nvidia.so.${VERSION} \
  libGLESv2_nvidia.so.${VERSION} \
  libGLX_nvidia.so.${VERSION} \
  libnvcuvid.so.${VERSION} \
  libnvidia-allocator.so.${VERSION} \
  libnvidia-eglcore.so.${VERSION} \
  libnvidia-encode.so.${VERSION} \
  libnvidia-fbc.so.${VERSION} \
  libnvidia-glcore.so.${VERSION} \
  libnvidia-glsi.so.${VERSION} \
  libnvidia-glvkspirv.so.${VERSION} \
  libnvidia-gpucomp.so.${VERSION} \
  libnvidia-ml.so.${VERSION} \
  libnvidia-nvvm.so.${VERSION} \
  libnvidia-opticalflow.so.${VERSION} \
  libnvidia-ptxjitcompiler.so.${VERSION} \
  libcudadebugger.so.${VERSION} \
  libnvidia-api.so.1 \
  libnvidia-cfg.so.${VERSION} \
  libnvidia-ngx.so.${VERSION} \
  libnvidia-rtcore.so.${VERSION} \
  libnvoptix.so.${VERSION} \
  ${LBIDIR}/

cp -af \
  libnvidia-opencl.so.${VERSION} \
  libnvidia-tls.so.${VERSION} \
  ${LBIDIR}/

# Use ldconfig for libraries with a mismatching SONAME/filename
ldconfig -vn ${LBIDIR}/

# Libraries you can link against
for lib in libcuda libnvcuvid libnvidia-encode libnvidia-ml libnvidia-nvvm; do
  ln -sf $lib.so.${VERSION} ${LBIDIR}/$lib.so
done

# Vdpau driver
install -D -p -m 0755 libvdpau_nvidia.so.${VERSION} ${LBIDIR}/vdpau/libvdpau_nvidia.so.${VERSION}
ln -sf libvdpau_nvidia.so.${VERSION} ${LBIDIR}/vdpau/libvdpau_nvidia.so.1

# GBM symlink
install -m 0755 -d ${LBIDIR}/gbm/
ln -sf ../libnvidia-allocator.so.${VERSION} ${LBIDIR}/gbm/nvidia-drm_gbm.so

# Vulkan loader
install -p -m 0644 -D nvidia_icd.json ${DATADIR}/vulkan/icd.d/nvidia_icd.json
sed -i -e 's|libGLX_nvidia|${LBIDIR}/libGLX_nvidia|g' ${DATADIR}/vulkan/icd.d/nvidia_icd.json

# EGL config for libglvnd
install -m 0755 -d ${DATADIR}/glvnd/egl_vendor.d/
install -p -m 0644 10_nvidia.json ${DATADIR}/glvnd/egl_vendor.d/10_nvidia.json

# Vulkan layer
install -p -m 0644 -D nvidia_layers.json ${DATADIR}/vulkan/implicit_layer.d/nvidia_layers.json

# X DDX driver and GLX extension
install -p -D -m 0755 libglxserver_nvidia.so.${VERSION} ${LBIDIR}/xorg/modules/extensions/libglxserver_nvidia.so
install -D -p -m 0755 nvidia_drv.so ${LBIDIR}/xorg/modules/drivers/nvidia_drv.so

# OpenCL config
install -m 0755 -d ${SYSCONFDIR}/OpenCL/vendors/
install -p -m 0644 nvidia.icd ${SYSCONFDIR}/OpenCL/vendors/

# Blacklist nouveau, autoload nvidia-uvm module after nvidia module
mkdir -p ${MODPROBEDIR}

printf '%s\n' 'softdep nvidia post: nvidia-uvm' >${MODPROBEDIR}/nvidia-uvm.conf
chmod 0644 ${MODPROBEDIR}/nvidia-uvm.conf

## Make a soft dependency for nvidia-uvm as adding the module loading to
## /usr/lib/modules-load.d/nvidia-uvm.conf for systemd consumption, makes the
## configuration file to be added to the initrd but not the module, throwing an
## error on plymouth about not being able to find the module.
## Ref: /usr/lib/dracut/modules.d/00systemd/module-setup.sh
##
## Even adding the module is not the correct thing, as we don't want it to be
## included in the initrd, so use this configuration file to specify the
## dependency.
##softdep nvidia post: nvidia-uvm

printf '%s\n' \
  'options nvidia NVreg_PreserveVideoMemoryAllocations=1' \
  'options nvidia NVreg_TemporaryFilePath=/var/tmp' \
  >${MODPROBEDIR}/nvidia-power-management.conf && chmod 0644 ${MODPROBEDIR}/nvidia-power-management.conf

## nvidia-power-management.conf
## Save and restore all video memory allocations.
#options nvidia NVreg_PreserveVideoMemoryAllocations=1
##
## The destination should not be using tmpfs, so we prefer
## /var/tmp instead of /tmp
#options nvidia NVreg_TemporaryFilePath=/var/tmp

# Install binaries
install -m 0755 -d ${BINDIR}
install -p -m 0755 nvidia-{bug-report.sh,debugdump,smi,cuda-mps-control,cuda-mps-server,ngx-updater,powerd} \
  ${BINDIR}

# Install VulkanSC config
# Vulkan SC loader and compiler
install -p -m 0644 -D nvidia_icd_vksc.json ${DATADIR}/vulkansc/icd.d/nvidia_icd_vksc.json
sed -i -e 's|libnvidia-vksc-core|${LBIDIR}/libnvidia-vksc-core|g' ${DATADIR}/vulkansc/icd.d/nvidia_icd_vksc.json
install -p -m 0755 nvidia-pcc ${BINDIR}

#Install wine dll
mkdir -p /usr/lib64/nvidia/wine/
install -p -m 0644 _nvngx.dll nvngx.dll /usr/lib64/nvidia/wine/

# Install man pages
install -m 0755 -d /usr/share/man/man1/
install -p -m 0644 nvidia-{cuda-mps-control,smi}.1.gz \
  /usr/share/man/man1/

#install the NVIDIA supplied application profiles
mkdir -p ${DATADIR}/nvidia
install -p -m 0644 nvidia-application-profiles-${VERSION}-{rc,key-documentation} ${DATADIR}/nvidia
install -p -m 0644 nvoptix.bin ${DATADIR}/nvidia
ln -s nvidia-application-profiles-${VERSION}-rc ${DATADIR}/nvidia/nvidia-application-profiles-rc
ln -s nvidia-application-profiles-${VERSION}-key-documentation ${DATADIR}/nvidia/nvidia-application-profiles-key-documentation

#Install the Xorg configuration files
mkdir -p ${SYSCONFDIR}/X11/xorg.conf.d
mkdir -p ${DATADIR}/X11/xorg.conf.d
#install -pm 0644 %{SOURCE6} ${DATADIR}/X11/xorg.conf.d/nvidia.conf

nvidia-xconfig --allow-empty-initial-configuration --no-sli --base-mosaic

#Create the default nvidia config directory
mkdir -p ${SYSCONFDIR}/nvidia

# TODO:
# install AppData and add modalias provides
#install -D -p -m 0644 %{SOURCE8} %{_metainfodir}/xorg-x11-drv-nvidia.metainfo.xml
#%{SOURCE9} supported-gpus/supported-gpus.json | xargs appstream-util add-provide %{_metainfodir}/xorg-x11-drv-nvidia.metainfo.xml modalias
mkdir -p ${DATADIR}/pixmaps
install -pm 0644 nvidia-settings.png ${DATADIR}/pixmaps/

UDEVRULESDIR=/usr/lib/udev/rules.d/
UNITDIR=/usr/lib/systemd/system
SYSTEMD_UTIL_DIR=/usr/lib/systemd/

# Install nvidia-fallback
install -m 0755 -d ${UNITDIR}
install -m 0755 -d ${UDEVRULESDIR}
install -p -m 0644 %{SOURCE13} ${UDEVRULESDIR}
install -p -m 0644 %{SOURCE14} ${UNITDIR}

# UDev rules for PCI-Express Runtime D3 (RTD3) Power Management

printf '%s\n' \
  '# Enable runtime PM for NVIDIA VGA/3D controller devices on driver bind' \
  'ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"' \
  'ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"' \
  '# Disable runtime PM for NVIDIA VGA/3D controller devices on driver unbind' \
  'ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"' \
  'ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"' \
  >${UDEVRULESDIR}/80-nvidia-pm.rules
chmod 0644 ${UDEVRULESDIR}/80-nvidia-pm.rules

# Systemd units and script for suspending/resuming
mkdir ${SYSTEMD_UTIL_DIR}/system-{sleep,preset}/
install -p -m 0644 %{SOURCE17} ${SYSTEMD_UTIL_DIR}/system-preset/
install -p -m 0644 systemd/system/nvidia-{hibernate,resume,suspend}.service ${UNITDIR}
install -p -m 0644 systemd/system/nvidia-powerd.service ${UNITDIR}
# Install dbus config
install -m 0755 -d %{_dbus_systemd_dir}
install -p -m 0644 nvidia-dbus.conf %{_dbus_systemd_dir}
# Ignore powerd binary exiting if hardware is not present
# We should check for information in the DMI table
sed -i -e 's/ExecStart=/ExecStart=-/g' ${UNITDIR}/nvidia-powerd.service
install -p -m 0755 systemd/system-sleep/nvidia ${SYSTEMD_UTIL_DIR}/system-sleep/
install -p -m 0755 systemd/nvidia-sleep.sh ${BINDIR}

# Firmware
mkdir -p /lib/firmware/nvidia/${VERSION}
install -p -m 0444 firmware/gsp_{ga,tu}10x.bin /lib/firmware/nvidia/${VERSION}/
