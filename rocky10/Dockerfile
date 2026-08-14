#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 2.0.0
#
# Distribution-consuming EPICS environment image.
# Same pattern as debian13. Base pinned to 10.2 because it matches
# the distribution build OS (rocky-10.2); new minors are followed promptly
# with a distribution rebuild - the rocky10 line exists to catch next-stable
# problems early.
FROM rockylinux/rockylinux:10.2

ARG DIST_REPO=https://github.com/jeonghanlee/EPICS-env-distribution.git
ARG DIST_VERSION=1.2.2
ARG OS_DIR=rocky-10.2
ARG EPICS_VERSION=7.0.10
ARG INSTALL_ROOT=/opt/epics
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles

LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky10-epics"
LABEL org.label-schema.description="Rocky Linux 10.2 EPICS environment from EPICS-env-distribution"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL epics.distribution-version=$DIST_VERSION
LABEL epics.base-version=$EPICS_VERSION

ENV TZ=${TZ}

# OS package layer. Derived from the rocky8 baseline with el10 package-name
# updates: crb replaces powertools, pcre2-devel replaces pcre-devel,
# libusb1-devel replaces libusb(x)-devel, python3 (3.12) is the distro
# default. libevent-devel explicit (pvxs links the system libevent).
# Pruned after a dependency review: dropped X11/Motif, netcdf/tiff/
# png, boost, pcre2, libcurl — none linked, header-referenced, or used by any
# consumer IOC build.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dnf install -y dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf install -y epel-release && \
    dnf --setopt=install_weak_deps=False install -y \
        git openssh-clients sudo bash make gcc-c++ perl perl-devel rpcgen \
        python3 python3-pip iproute socat \
        readline-devel libevent-devel net-snmp net-snmp-utils net-snmp-devel \
        libtirpc libtirpc-devel libxml2-devel systemd-devel \
        libusb1-devel hdf5-devel libjpeg-turbo-devel \
        libssh2 libssh2-devel python3-devel \
        ncurses-devel && \
    ln -snf /usr/bin/python3 /usr/local/bin/python && \
    dnf clean all && rm -rf /var/cache/dnf /var/cache/yum

# Distribution layer: sparse fetch of exactly one OS tree, placed at the
# versioned install root, bake manifest recorded, .git removed - one layer.
RUN git clone --depth 1 --filter=blob:none --sparse "${DIST_REPO}" /tmp/dist && \
    git -C /tmp/dist sparse-checkout set "${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" && \
    install -d "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}" && \
    mv "/tmp/dist/${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}" "${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}/" && \
    printf '%s %s %s %s\n' EPICS-env-distribution "${DIST_REPO}" "$(git -C /tmp/dist rev-parse HEAD)" "$(date -u +%FT%TZ)" > /etc/epics-bake.manifest && \
    rm -rf /tmp/dist

# IOC runtime tools: procServ and con, built from source in the
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

# Baked environment: variable list and PATH order
# follow the verified setEpicsEnv.bash baseline; LD_LIBRARY_PATH carries the
# base lib dir only - modules resolve through their RUNPATH.
ENV EPICS_PATH=${INSTALL_ROOT}/${DIST_VERSION}/${OS_DIR}/${EPICS_VERSION}
ENV EPICS_BASE=${EPICS_PATH}/base \
    EPICS_MODULES=${EPICS_PATH}/modules \
    EPICS_HOST_ARCH=linux-x86_64
ENV PATH=${EPICS_MODULES}/pmac/bin/linux-x86_64:${EPICS_MODULES}/pvxs/bin/linux-x86_64:${EPICS_BASE}/bin/linux-x86_64:${PATH}
ENV LD_LIBRARY_PATH=${EPICS_BASE}/lib/linux-x86_64

CMD ["/bin/bash"]
