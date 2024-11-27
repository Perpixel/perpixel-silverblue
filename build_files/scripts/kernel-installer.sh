# install longterm kernel from copr
# longterm kernel https://copr.fedorainfracloud.org/coprs/kwizart/kernel-longterm-6.6/

set -oeux pipefail

DEV_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
  --devel)
    DEV_ONLY=true
    shift
    ;;
  esac
done

dnf5 copr enable kwizart/kernel-longterm-6.6 -y

if [ "${DEV_ONLY}" == true ]; then
  dnf install -y g++ kmod patch kernel-longterm-devel
  KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-longterm-devel)
else
  rpm-ostree cliwrap install-to-root /
  rpm -e kernel kernel-{core,modules-core,modules,modules-extra,tools,tools-libs}
  rpm-ostree install kernel-longterm kernel-longterm-{core,modules,modules-extra,modules-core}
  # rpm-ostree override remove kernel kernel-{core,modules,modules-extra,modules-core,tools,tools-libs} \
  #   --install kernel-longterm \
  #   --install kernel-longterm-modules-core \
  #   --install kernel-longterm-core \
  #   --install kernel-longterm-modules \
  #   --install kernel-longterm-modules-extra
  KERNEL_VERSION=$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-longterm)
fi
