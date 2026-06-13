#!/bin/bash
# Build patched MT7927 (mt7925e) WiFi + Bluetooth kernel modules from source.
# Sources: linux-7.0 kernel tree (mt76 + bluetooth) + ASUS firmware ZIP.
# Output: /output/{usr/lib/modules,usr/lib/firmware,etc/depmod.d,etc/modules-load.d}

set -ouex pipefail

BUILD_DIR="/tmp/mt7927-build"
OUTPUT_DIR="/output"

KVER=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' | tail -1)
echo "Building MT7927 modules for kernel: ${KVER}"

# Install build dependencies
dnf install -y \
    gcc make "kernel-devel-${KVER}" kernel-headers \
    python3 curl patch xz unzip git

mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Clone the DKMS repo which contains all patches, Kbuild files, and helper scripts
git clone --depth 1 https://github.com/jetm/mediatek-mt7927-dkms.git dkms

cd dkms

# Download: linux-7.0 tarball from kernel.org + ASUS firmware ZIP via token API
make download

# Extract sources, apply all mt7927-wifi-* and mt6639-bt-* patches, install Kbuild files
make sources

SRCDIR="${BUILD_DIR}/dkms/_build"
KSRC="/lib/modules/${KVER}/build"

# Build patched WiFi modules (mt76 tree)
make -C "${KSRC}" M="${SRCDIR}/mt76" -j"$(nproc)" modules

# Build patched Bluetooth modules only if the upstream kernel lacks MT6639 support
if ! grep -q 'MT6639' "${KSRC}/drivers/bluetooth/btmtk.h" 2>/dev/null; then
    make -C "${KSRC}" M="${SRCDIR}/bluetooth" -j"$(nproc)" modules
fi

# Stage kernel modules
INSTALL_DIR="${OUTPUT_DIR}/usr/lib/modules/${KVER}/extra/mt7927"
mkdir -p "${INSTALL_DIR}"

install -m644 \
    "${SRCDIR}/mt76/mt76.ko" \
    "${SRCDIR}/mt76/mt76-connac-lib.ko" \
    "${SRCDIR}/mt76/mt792x-lib.ko" \
    "${INSTALL_DIR}/"
install -m644 \
    "${SRCDIR}/mt76/mt7921/mt7921-common.ko" \
    "${SRCDIR}/mt76/mt7921/mt7921e.ko" \
    "${INSTALL_DIR}/"
install -m644 \
    "${SRCDIR}/mt76/mt7925/mt7925-common.ko" \
    "${SRCDIR}/mt76/mt7925/mt7925e.ko" \
    "${INSTALL_DIR}/"

if [ -f "${SRCDIR}/bluetooth/btusb.ko" ]; then
    install -m644 \
        "${SRCDIR}/bluetooth/btusb.ko" \
        "${SRCDIR}/bluetooth/btmtk.ko" \
        "${INSTALL_DIR}/"
fi

xz --check=crc32 -f "${INSTALL_DIR}"/*.ko

# Stage firmware
install -Dm644 \
    "${SRCDIR}/firmware/BT_RAM_CODE_MT6639_2_1_hdr.bin" \
    "${OUTPUT_DIR}/usr/lib/firmware/mediatek/mt7927/BT_RAM_CODE_MT6639_2_1_hdr.bin"
install -Dm644 \
    "${SRCDIR}/firmware/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin" \
    "${OUTPUT_DIR}/usr/lib/firmware/mediatek/mt7927/WIFI_MT6639_PATCH_MCU_2_1_hdr.bin"
install -Dm644 \
    "${SRCDIR}/firmware/WIFI_RAM_CODE_MT6639_2_1.bin" \
    "${OUTPUT_DIR}/usr/lib/firmware/mediatek/mt7927/WIFI_RAM_CODE_MT6639_2_1.bin"

# Ensure extra/ modules override the stock in-tree mt76 modules
install -Dm644 /dev/stdin "${OUTPUT_DIR}/etc/depmod.d/mt7927.conf" <<'EOF'
search extra updates built-in weak-updates override
EOF

# Load mt7925e at boot (covers both MT7925 and MT7927 via the patched module)
mkdir -p "${OUTPUT_DIR}/etc/modules-load.d"
echo "mt7925e" > "${OUTPUT_DIR}/etc/modules-load.d/mt7925e.conf"

echo "MT7927 driver build complete."
