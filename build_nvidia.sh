podman run -it --rm \
  --device /dev/video0 \
  --device /dev/nvidia0 \
  --device /dev/nvidia-uvm \
  --device /dev/nvidia-modeset \
  --device /dev/dri \
  -v /var/home/guillaume/Downloads/vkQuake/:/tmp/vkQuake:z \
  -v ./build_files/scripts:/tmp/scripts:z \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --security-opt=label=type:container_runtime_t \
  --privileged \
  --group-add keep-groups \
  -u 0 -e DISPLAY="$DISPLAY" \
  localhost/nvidia-perpixel-silverblue:latest sh -c "/tmp/vkQuake/build/vkquake -basedir /tmp/vkQuake"
# quay.io/fedora/fedora:41 sh -c "/tmp/scripts/build-nvidia-drv.sh && bash" #/tmp/vkQuake/build/vkquake -basedir /tmp/vkQuake"
