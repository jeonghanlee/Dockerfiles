#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#
##
## BuildEnv docker image size :
FROM rockylinux/rockylinux:10 AS builder
#
ARG INSTALL_LOCATION=/usr/local
#
RUN export LC_CTYPE=C.UTF-8 && export LC_ALL=C.UTF-8 && \
    dnf install -y git sudo bash wget unzip make && \
    git clone --depth 1 https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    dnf install -y python3-pip && \
    pip3 install numpy && \
    git clone --depth 1 https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github && \
    git clone --depth 1 https://github.com/jeonghanlee/open62541-env.git && \
    make -C open62541-env github
#
RUN git clone https://github.com/jeonghanlee/EPICS-env && \
    bash EPICS-env/scripts/build_epics.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/install_apps.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/als.bash
## Multi-Stages build
## Running docker image size : 2.2GB
FROM rockylinux/rockylinux:10
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles
# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky10-epics"
LABEL org.label-schema.description="Rocky 10 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=rk10epics jeonghanlee/rocky10-epics"
# shellcheck will be installed through EPICS-env/scripts/install_apps.bash in builder...
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dnf update -y && \
    dnf install -y git sudo bash vi langpacks-en && \
    git clone --depth 1 https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    git clone --depth 1 https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github && \
    rm -rf uldaq-env && \
    git clone --depth 1 https://github.com/jeonghanlee/open62541-env.git && \
    make -C open62541-env github && \
    rm -rf open62541-env && \
    dnf install -y java-21-openjdk python3-pip cppcheck && \
    pip3 install gcovr==5.0 flawfinder==2.0.8 pyparsing==2.4.2 numpy && \
    dnf clean all && rm -rf /var/cache/dnf/*
#
WORKDIR ${INSTALL_LOCATION}
#
COPY --from=builder ${INSTALL_LOCATION}/epics epics
COPY --from=builder ${INSTALL_LOCATION}/apps apps
COPY --from=builder ${INSTALL_LOCATION}/setEnv setEnv
#
RUN mkdir -p /vxboot/PVenv /vxboot/PVnames
#
SHELL [ "/bin/bash" ]
ENTRYPOINT [ "" ]
#
