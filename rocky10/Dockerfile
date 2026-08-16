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
ARG PROCSERV_ENV_VERSION=1.0.0
ARG CON_VERSION=1.1.0
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

# Distribution layer: sparse fetch of exactly one OS tree at the DIST_VERSION
# tag, placed at the versioned install root, bake manifest recorded, .git
# removed - one layer. The tag pins the fetch so the same DIST_VERSION always
# resolves to the same distribution commit. --branch takes the tag directly in
# this one shallow clone; a plain clone plus git checkout <tag> would fail,
# since --depth 1 does not carry the history the tag needs.
RUN git clone --depth 1 --filter=blob:none --sparse --branch "${DIST_VERSION}" "${DIST_REPO}" /tmp/dist && \
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
    git clone --depth 1 --branch "${PROCSERV_ENV_VERSION}" https://github.com/jeonghanlee/procServ-env /tmp/procServ-env && \
    make -C /tmp/procServ-env init && make -C /tmp/procServ-env conf && \
    make -C /tmp/procServ-env build && make -C /tmp/procServ-env install && \
    printf '%s %s %s %s\n' procServ-env https://github.com/jeonghanlee/procServ-env "$(git -C /tmp/procServ-env rev-parse HEAD)" "$(date -u +%FT%TZ)" >> /etc/epics-bake.manifest && \
    git clone --depth 1 --branch "${CON_VERSION}" https://github.com/jeonghanlee/con /tmp/con && \
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

# CI environment contract: /usr/local/setEnv restores the EPICS bin directories
# on PATH for a login shell, which reruns /etc/profile and drops them. POSIX sh
# only, so any CI shell can source it, matching the contract the previous images
# offered through their own setEnv. See the file header for why the interactive
# setEpicsEnv.bash is not used for one-shot CI sourcing.
RUN cat > /usr/local/setEnv <<'SETENV'
# source /usr/local/setEnv
#
# This image bakes the EPICS environment as ENV: EPICS_PATH, EPICS_BASE,
# EPICS_MODULES, EPICS_HOST_ARCH, and LD_LIBRARY_PATH. A login shell reruns
# /etc/profile, which overwrites PATH and drops the EPICS bin directories; a
# non-login shell keeps them. This file restores the EPICS bin directories on
# PATH so sourcing it is safe in either shell.
#
# It replaces, for one-shot CI use, the interactive setEpicsEnv.bash, whose
# re-source guards, arch detection, and module symlink handling are unnecessary
# when a fresh container sources the environment exactly once. POSIX sh only -
# no bash syntax - so any CI shell can source it.
#
# A login shell on a bash-/bin/sh image inherits the baked PATH before this
# runs, so strip any existing EPICS bin entries first, then prepend once. This
# keeps sourcing idempotent and avoids duplicate PATH entries.
_epics_pmac="${EPICS_MODULES}/pmac/bin/${EPICS_HOST_ARCH}"
_epics_pvxs="${EPICS_MODULES}/pvxs/bin/${EPICS_HOST_ARCH}"
_epics_base="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}"
PATH=$(printf '%s' ":${PATH}:" | sed -e "s#:${_epics_pmac}:#:#g" -e "s#:${_epics_pvxs}:#:#g" -e "s#:${_epics_base}:#:#g" -e 's#^:##' -e 's#:$##')
PATH="${_epics_pmac}:${_epics_pvxs}:${_epics_base}:${PATH}"
export PATH
unset _epics_pmac _epics_pvxs _epics_base
SETENV

CMD ["/bin/bash"]
