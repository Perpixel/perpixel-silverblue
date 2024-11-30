#!/bin/bash

echo "### Kernel command line"
cat /proc/cmdline
echo

echo "### Nvidia driver version"
cat /proc/driver/nvidia/version
echo

echo "### loaded nvidia modules"
lsmod | grep nvidia
echo

echo "### Modules parameters"
echo Module: nvidia
cat /proc/driver/nvidia/params
echo

declare -a modules=("nvidia_drm" "nvidia_modset" "nvidia_uvm")
for module in "${modules[@]}"; do
  echo "$module:"
  if [ -d "/sys/module/$module/parameters" ]; then
    ls /sys/module/$module/parameters/ | while read param; do
      echo -n "    $param: "
      cat /sys/module/$module/parameters/$param
    done
  fi
  echo
done

echo "### Nvidia services status"
declare -a services=("nvidia-hibernate" "nvidia-resume" "nvidia-suspend" "nvidia-persistenced" "nvidia-powerd")
echo Services:
for service in "${services[@]}"; do
  echo "    $service: $(systemctl is-enabled ${service})"
done
echo

echo "### Nvidia services status"
if command -v rpm &> /dev/null; then
	echo "$(rpm -qa | grep  -E 'gnome-session|xorg')"
fi
