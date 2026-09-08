#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.0
#
# Runtime-only slim image (variant B): a toolchain-free base that runs a baked
# IOC under the ioc-runner supervision layer. The IOC (tc32sim) is compiled in
# the development image and copied into this slim final stage; no build
# toolchain ships here. Rocky packages no s6/execline, so the statically built
# supervision binaries are copied from the development image.
ARG IMAGE_VERSION=1.0.1

# Stage 1: build the IOC in the development image (toolchain + EPICS modules).
FROM jeonghanlee/rocky8-epics:${IMAGE_VERSION} AS build
ARG IOC_REPO=https://github.com/jeonghanlee/tc32sim.git
RUN git clone --depth 1 "${IOC_REPO}" /opt/ioc/tc32sim && \
    printf 'EPICS_BASE=%s\n' "${EPICS_BASE}" > /opt/ioc/tc32sim/configure/RELEASE.local && \
    make -C /opt/ioc/tc32sim

# Stage 2: slim runtime.
FROM rockylinux/rockylinux:8.10
ARG RUNNER_VERSION=1.4.0
ARG RUNNER_REPO=https://github.com/jeonghanlee/epics-ioc-runner.git
ARG BUILD_DATE
ARG BUILD_VERSION

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky8-epics-slim"
LABEL org.label-schema.description="Rocky Linux 8 slim runtime image running a baked IOC through ioc-runner"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL epics.runner-version=$RUNNER_VERSION

# Runtime OS set: the EPICS runtime libraries and the ioc-runner utilities - no
# build toolchain. Only the direct EPICS dependencies are named; dnf resolves
# the transitive libraries. s6 and execline are copied from the dev image.
# The rockylinux base ships binutils (ld/as/readelf); remove it to keep the
# runtime image toolchain-free, matching the debian and ubuntu slim images.
RUN dnf --setopt=install_weak_deps=False install -y \
        ca-certificates bash git findutils \
        iproute socat lsof procps-ng gawk \
        readline libtirpc libxml2 openssl-libs zlib \
        net-snmp-libs libevent libusbx systemd-libs && \
    dnf remove -y binutils && \
    dnf clean all && rm -rf /var/cache/dnf /var/cache/yum

# EPICS runtime tree and IOC/supervision tools from the development image (no
# compilation): procServ, con, and the statically built s6/execline set under
# /usr/local/bin.
COPY --from=build /opt/epics /opt/epics
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /etc/epics-bake.manifest /etc/epics-bake.manifest

# Baked EPICS environment (mirrors the development image).
ENV EPICS_PATH=/opt/epics/1.2.2/rocky-8.10/7.0.10
ENV EPICS_BASE=${EPICS_PATH}/base \
    EPICS_MODULES=${EPICS_PATH}/modules \
    EPICS_HOST_ARCH=linux-x86_64
ENV PATH=${EPICS_MODULES}/pmac/bin/linux-x86_64:${EPICS_MODULES}/pvxs/bin/linux-x86_64:${EPICS_BASE}/bin/linux-x86_64:${PATH}
ENV LD_LIBRARY_PATH=${EPICS_BASE}/lib/linux-x86_64

# ioc-runner supervision layer (same fragment as the runner images).
RUN git clone --depth 1 --branch "${RUNNER_VERSION}" "${RUNNER_REPO}" /tmp/runner && \
    /bin/bash -p /tmp/runner/bin/setup-system-infra.bash --container && \
    printf '%s %s %s %s\n' epics-ioc-runner "${RUNNER_REPO}" "$(git -C /tmp/runner rev-parse HEAD)" "$(date -u +%FT%TZ)" >> /etc/epics-bake.manifest && \
    rm -rf /tmp/runner

# Entry point: create the scan directory and run s6-svscan as PID 1.
RUN printf '%s\n' \
      '#!/bin/bash' \
      'set -eu' \
      'mkdir -p /run/s6-procserv' \
      'exec s6-svscan /run/s6-procserv' \
      > /usr/local/bin/s6-svscan-entrypoint && \
    chmod 0755 /usr/local/bin/s6-svscan-entrypoint

# Baked IOC: the tc32sim tree built in stage 1 at its final path, owned by the
# service account so the running IOC can write iocsh history and autosave files.
COPY --from=build --chown=ioc-srv:ioc /opt/ioc/tc32sim /opt/ioc/tc32sim

ENTRYPOINT ["/usr/local/bin/s6-svscan-entrypoint"]
