ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_VERSION="${FEDORA_VERSION}"

# Stage 1: Build MT7927 kernel modules
FROM ${BASE_IMAGE}:${FEDORA_VERSION} AS builder
ARG BUILDROOT=/build
COPY build_files/ "${BUILDROOT}"
RUN rpm-ostree cliwrap install-to-root / \
  && "${BUILDROOT}"/scripts/build-mt7927-modules.sh

# Stage 2: Build final image
FROM ${BASE_IMAGE}:${FEDORA_VERSION}
ARG BUILDROOT=/build

# Copy build scripts
COPY build_files/ "${BUILDROOT}"
# Copy MT7927 kernel modules, firmware, and config from builder stage
COPY --from=builder /output/ /
# Copy configuration files to root
COPY ./system_files/. /
# Run installer and commit image
RUN rpm-ostree cliwrap install-to-root / \
  && "${BUILDROOT}"/scripts/install.sh \
  && depmod -a "$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' | tail -1)" \
  && ostree container commit \
  && rm -rf "${BUILDROOT}" \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
