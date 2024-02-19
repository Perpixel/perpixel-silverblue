#!/bin/sh

set -oeux pipefail

KERNELRELEASE="$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"

# install tools
rpm-ostree install cabextract lld dkms

ln -s /usr/bin/lld /usr/bin/ld

# build
git clone https://github.com/perpixel/xone /tmp/xone
cd /tmp/xone
#make -j16 KERNELRELEASE=6.7.4-200.fc39.x86_64 -C /lib/modules/6.7.4-200.fc39.x86_64/build
make -j16 -C /lib/modules/"${KERNELRELEASE}"/build M=$PWD

# firmware
curl -L -o driver.cab http://download.windowsupdate.com/c/msdownload/update/driver/drvs/2017/07/1cd6a87c-623f-4407-a52d-c31be49e925c_e19f60808bdcbfbd3c3df6be3e71ffc52e43261e.cab
cabextract -F FW_ACC_00U.bin driver.cab
mv FW_ACC_00U.bin xow_dongle.bin
