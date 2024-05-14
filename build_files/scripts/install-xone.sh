#!/usr/bin/bash

set -oue pipefail

echo -e "\
  blacklist xpad\n\
  blacklist mt76x2u\
  " >/etc/modprobe.d/xone-blacklist.conf
