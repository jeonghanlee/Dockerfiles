#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 2.0.0
#
# Distribution-consuming EPICS environment image (register M2.1).
# Prebuilt binaries come from EPICS-env-distribution; nothing EPICS is
# compiled while building this image (D2). The consumer build toolchain is
# resident because runner jobs compile IOCs inside the running container.
# The environment is baked via ENV (D3) - no setEnv sourcing contract.
FROM debian:trixie-slim

ARG DIST_REPO=https://github.com/jeonghanlee/EPICS-env-distribution.git
ARG DIST_VERSION=1.2.1
ARG OS_DIR=debian-13
ARG EPICS_VERSION=7.0.10
ARG INSTALL_ROOT=/opt/epics
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles

LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/debian13-epics"
LABEL org.label-schema.description="Debian 13 EPICS environment from EPICS-env-distribution"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL epics.distribution-version=$DIST_VERSION
LABEL epics.base-version=$EPICS_VERSION

ENV TZ=${TZ}

# OS package layer, kept separate from the distribution fetch so a
# distribution version bump does not invalidate this cache layer.
# Package baseline: ansible-provision inventory/group_vars/debian13.yml
# pkg_standard plus the Python consumer set; analyzers excluded per D5.
# Exact runtime pruning is register task M2.4.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates git build-essential perl bash sudo vim \
        python3 python3-pip python3-numpy python3-pyparsing python-is-python3 \
        iproute2 socat \
        libreadline-dev libsnmp-dev libevent-dev libtirpc-dev libxml2-dev \
        libusb-1.0-0-dev libudev-dev libsystemd-dev libssl-dev libbz2-dev \
        libhdf5-dev libnetcdf-dev libtiff-dev libjpeg-dev libpng-dev libz-dev \
        libboost-dev libboost-regex-dev libboost-filesystem-dev \
        libssh2-1-dev libhidapi-dev libhidapi-libusb0 \
        libxt-dev libxmu-dev libxpm-dev libmotif-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Distribution layer: sparse fetch of exactly one OS tree, placed at the
# versioned install root, bake manifest recorded, .git removed - one layer.
RUN git clone --depth 1 --filter=blob:none --sparse "${DIST_REPO}" /tmp/dist && \
    git -C /tmp/dist sparse-checkout set "${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" && \
    install -d "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}" && \
    mv "/tmp/dist/${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}/" && \
    printf '%s %s %s %s\n' EPICS-env-distribution "${DIST_REPO}" "$(git -C /tmp/dist rev-parse HEAD)" "$(date -u +%FT%TZ)" > /etc/epics-bake.manifest && \
    rm -rf /tmp/dist

# Baked environment (D3, ratified 2026-07-18): variable list and PATH order
# follow the verified setEpicsEnv.bash baseline; LD_LIBRARY_PATH carries the
# base lib dir only - modules resolve through their RUNPATH.
ENV EPICS_PATH=${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}
ENV EPICS_BASE=${EPICS_PATH}/base \
    EPICS_MODULES=${EPICS_PATH}/modules \
    EPICS_HOST_ARCH=linux-x86_64
ENV PATH=${EPICS_MODULES}/pmac/bin/linux-x86_64:${EPICS_MODULES}/pvxs/bin/linux-x86_64:${EPICS_BASE}/bin/linux-x86_64:${PATH}
ENV LD_LIBRARY_PATH=${EPICS_BASE}/lib/linux-x86_64

CMD ["/bin/bash"]
