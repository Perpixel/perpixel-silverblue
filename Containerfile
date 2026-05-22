ARG BASE_IMAGE="${BASE_IMAGE}"
ARG FEDORA_VERSION="${FEDORA_VERSION}"

# Build final image

FROM ${BASE_IMAGE}:${FEDORA_VERSION}
ARG BUILDROOT=/build

# Copy build scripts
COPY build_files/ "${BUILDROOT}"
# Copy configuration files to root
COPY ./system_files/. /
# Run installer and commit image
RUN rpm-ostree cliwrap install-to-root / \
  && "${BUILDROOT}"/scripts/install.sh \
  && ostree container commit \
  && rm -rf "${BUILDROOT}" \
  && mkdir -p /var/tmp && chmod -R 1777 /var/tmp
