#!/bin/sh

set -oeux pipefail

RELEASE="$(rpm -E '%fedora.%_arch')"
ARCH="$(rpm -E '%_arch')"

NVIDIA_PACKAGE_NAME="nvidia"
BUILD_PATH=/tmp/nvidia-drv
RPMBUILD_PATH=${BUILD_PATH}/rpmbuild
SOURCES_PATH=${RPMBUILD_PATH}/SOURCES
RPMS_PATH=${BUILD_PATH}/rpmbuild/RPMS/${ARCH}

if command -v dnf5 &> /dev/null; then alias dnf=dnf5; fi

build_rpm() {
  rpmbuild ${1} --bb --define "_topdir ${BUILD_PATH}/rpmbuild"
}

setup_rpm_build_env() {

  mkdir -p /tmp/nvidia-drv

  dnf install wget git -y

  wget https://download.nvidia.com/XFree86/Linux-x86_64/560.35.03/NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run
  df -h
  sh /tmp/nvidia-drv/rpmbuild/SOURCES/NVIDIA-Linux-x86_64-560.35.03.run --extract-only --target nvidiapkg
  
  # download and install rpm fusion package
  wget -P /tmp/rpms \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm
  dnf install /tmp/rpms/*.rpm fedora-repos-archive -y

dnf install \
  rpm-build rpmspectool libappstream-glib systemd-rpm-macros rpmdevtools gcc \
  mesa-libGL-devel mesa-libEGL-devel libvdpau-devel libXxf86vm-devel libXv-devel \
  desktop-file-utils hostname gtk3-devel m4 pkgconfig mock libtirpc-devel \
  buildsys-build-rpmfusion-kerneldevpkgs-current elfutils-libelf-devel vulkan-headers -y
}

setup_sources() {
  echo Setting up ${1} sources...
  mkdir -p ${RPMBUILD_PATH}
  ln -nsf ${BUILD_PATH}/${1} ${SOURCES_PATH}
  cd ${SOURCES_PATH}
}

pull_git_repos() {
  echo Clone required RPM Fusion projects from Github...
  cd ${BUILD_PATH}
  git clone https://github.com/rpmfusion/xorg-x11-drv-nvidia.git
  git clone https://github.com/rpmfusion/nvidia-kmod.git
  git clone https://github.com/rpmfusion/nvidia-modprobe.git
  git clone https://github.com/rpmfusion/nvidia-xconfig.git
  git clone https://github.com/rpmfusion/nvidia-settings.git
  git clone https://github.com/rpmfusion/nvidia-persistenced.git
}

build_driver() {
  # xorg-x11-drv-nvidia
  setup_sources xorg-x11-drv-nvidia
  NVIDIA_SPEC=$(ls xorg-x11-drv-nvidia*.spec)
  NVIDIA_VERSION=$(grep ^Version: ${NVIDIA_SPEC} | awk '{print $2}')
  wget https://download.nvidia.com/XFree86/Linux-x86_64/560.35.03/NVIDIA-Linux-${ARCH}-${NVIDIA_VERSION}.run
  df -h
  sh /tmp/nvidia-drv/rpmbuild/SOURCES/NVIDIA-Linux-x86_64-560.35.03.run --extract-only --target nvidiapkg
  build_rpm xorg-x11-drv-nvidia.spec
  dnf install ${RPMS_PATH}/xorg-x11-drv-nvidia-kmodsrc-*.rpm -y
}

build_kmod() {
  # nvidia-kmod
  echo Build NVIDIA-KDMOD...
  setup_sources nvidia-kmod
  mkdir -p ${RPMBUILD_PATH}/SPECS
  # ln -nsf nvidia-kmod.spec ${RPMBUILD_PATH}/SPECS/nvidia-kmod.spec
  cp ./nvidia-kmod.spec ${RPMBUILD_PATH}/SPECS/nvidia-kmod.spec
  build_rpm ${RPMBUILD_PATH}/SPECS/nvidia-kmod.spec
}

build_app() {
  name=${1}
  echo Starting ${name} rpm build...
  setup_sources ${name}
  wget https://download.nvidia.com/XFree86/${name}/${name}-${NVIDIA_VERSION}.tar.bz2
  build_rpm ${name}.spec
}

build_apps() {
  # nvidia-modprobe
  build_app nvidia-modprobe

  # nvidia-setting
  build_app nvidia-settings

  # nvidia-xconfig
  build_app nvidia-xconfig

  # nvidia-persistenced
  build_app nvidia-persistenced
}

setup_rpm_build_env
pull_git_repos
build_driver
build_kmod
build_apps

cd ${RPMBUILD_PATH}/RPMS/x86_64/

dnf install \
  ./akmod-nvidia-${NVIDIA_VERSION}-1.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-cuda-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-cuda-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-devel-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-kmodsrc-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-xorg-libs-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-power-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./xorg-x11-drv-nvidia-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./kmod-nvidia-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./nvidia-modprobe-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./nvidia-settings-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./nvidia-xconfig-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  ./nvidia-persistenced-${NVIDIA_VERSION}-*.fc${RELEASE}.rpm \
  mock -y

exit

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
