ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_VERSION="${FEDORA_VERSION}"
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"

# Build NVIDIA drivers
#
# This will build the rpm from rpmfusion source and then make
# them available to the final image in this container.i

FROM ${BASE_IMAGE}:${FEDORA_VERSION} as nvidia-builder
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
ARG BUILDROOT=/build
COPY build_files/ "${BUILDROOT}"
RUN rpm-ostree cliwrap install-to-root / \
  && "${BUILDROOT}"/scripts/nvidia-modules-build.sh

# Build final image
#

FROM ${BASE_IMAGE}:${FEDORA_VERSION}
ARG NVIDIA_VERSION="${NVIDIA_VERSION}"
ARG BUILDROOT=/build

# Copy build scripts
COPY build_files/ "${BUILDROOT}"
# Copy built modules from nvidia-builder step
COPY --from=nvidia-builder /build/modules "${BUILDROOT}"/nvidia-modules
# Copy configuration files to root
COPY system_files /
# Copy cosign public key
COPY cosign.pub /usr/etc/pki/containers/perpixel.pub
# Run installer and commit image
RUN rpm-ostree cliwrap install-to-root / \
  && "${BUILDROOT}"/scripts/install.sh \
  && ostree container commit \
  && rm -rf "${BUILDROOT}" \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
