#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 2.0.0
#
# Distribution-consuming EPICS environment image (register M2.2).
# Same pattern as debian13 (M2.1): prebuilt EPICS-env-distribution binaries,
# ENV-baked environment (D3), resident consumer toolchain (D2).
FROM rockylinux/rockylinux:8.10

ARG DIST_REPO=https://github.com/jeonghanlee/EPICS-env-distribution.git
ARG DIST_VERSION=1.2.2
ARG OS_DIR=rocky-8.10
ARG EPICS_VERSION=7.0.10
ARG INSTALL_ROOT=/opt/epics
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles

LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky8-epics"
LABEL org.label-schema.description="Rocky Linux 8.10 EPICS environment from EPICS-env-distribution"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL epics.distribution-version=$DIST_VERSION
LABEL epics.base-version=$EPICS_VERSION

ENV TZ=${TZ}

# OS package layer. Baseline: ansible-provision group_vars/rocky8.yml
# pkg_standard minus VM-only entries (firewalld); libevent-devel added
# explicitly (pvxs links the system libevent; absent from the VM baseline).
# The `python` links serve base's MAKERPATH, which invokes plain python.
# Pruned per M2.4 (review rs20260718_192908): dropped X11/Motif, netcdf/tiff/
# png, boost, the PCRE1 pcre-devel family, libcurl, and the legacy libusb 0.1
# API — none linked, header-referenced, or used by any consumer IOC build.
# (pcre2-devel stays: a transitive capability dep of libselinux-devel, not
# cleanly removable; deferred to M7.3.)
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled powertools && \
    dnf install -y epel-release && \
    dnf --setopt=install_weak_deps=False install -y \
        git openssh-clients sudo bash make gcc-c++ perl perl-devel rpcgen \
        python39 python39-pip iproute socat \
        readline-devel libevent-devel net-snmp net-snmp-utils net-snmp-devel \
        libtirpc libtirpc-devel libxml2-devel systemd-devel \
        libusbx-devel hdf5-devel libjpeg-turbo-devel \
        libssh2 libssh2-devel python3-devel \
        flex-devel ncurses-devel && \
    ln -snf /usr/bin/python3.9 /usr/local/bin/python && \
    ln -snf /usr/bin/python3.9 /usr/local/bin/python3 && \
    dnf clean all && rm -rf /var/cache/dnf /var/cache/yum

# Distribution layer: sparse fetch of exactly one OS tree, placed at the
# versioned install root, bake manifest recorded, .git removed - one layer.
RUN git clone --depth 1 --filter=blob:none --sparse "${DIST_REPO}" /tmp/dist && \
    git -C /tmp/dist sparse-checkout set "${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" && \
    install -d "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}" && \
    mv "/tmp/dist/${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}/" && \
    printf '%s %s %s %s\n' EPICS-env-distribution "${DIST_REPO}" "$(git -C /tmp/dist rev-parse HEAD)" "$(date -u +%FT%TZ)" > /etc/epics-bake.manifest && \
    rm -rf /tmp/dist

# IOC runtime tools (register M3.1): procServ and con, built from source in the
# final image (recipes mirror ansible-provision app_procserv / app_con). The
# autotools set procServ needs (autoconf/automake/libtool) is not needed by
# consumer IOC builds, so it is installed and removed within this one layer.
RUN set -e; \
    dnf install -y autoconf automake libtool && \
    git clone --depth 1 https://github.com/jeonghanlee/procServ-env /tmp/procServ-env && \
    make -C /tmp/procServ-env init && make -C /tmp/procServ-env conf && \
    make -C /tmp/procServ-env build && make -C /tmp/procServ-env install && \
    printf '%s %s %s %s\n' procServ-env https://github.com/jeonghanlee/procServ-env "$(git -C /tmp/procServ-env rev-parse HEAD)" "$(date -u +%FT%TZ)" >> /etc/epics-bake.manifest && \
    git clone --depth 1 https://github.com/jeonghanlee/con /tmp/con && \
    make -C /tmp/con && make -C /tmp/con install DESTDIR=/usr/local && \
    printf '%s %s %s %s\n' con https://github.com/jeonghanlee/con "$(git -C /tmp/con rev-parse HEAD)" "$(date -u +%FT%TZ)" >> /etc/epics-bake.manifest && \
    dnf remove -y autoconf automake libtool && dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /tmp/procServ-env /tmp/con && \
    test -x /usr/local/bin/procServ && test -x /usr/local/bin/con

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
