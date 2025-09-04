#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3
##
## BuildEnv docker image size : GB
FROM amd64/debian:bullseye AS builder
#
ARG INSTALL_LOCATION=/usr/local
#
RUN apt update -y && \
    apt install -y  git sudo bash wget unzip make && \
    git clone --depth 1 https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    apt install -y python3-pip && \
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
# Multi-Stages build
# Running docker image size : GB
FROM amd64/debian:bullseye
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles
## Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/debian11-epics"
LABEL org.label-schema.description="Debian 11 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=deb11epics jeonghanlee/debian11-epics /bin/bash"
#
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt update -y && \
    apt install -y git sudo bash vim && \
    git clone --depth 1 https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    apt install -y openjdk-17-jre shellcheck splint cppcheck python3-pip && \
    pip3 install gcovr==5.0 flawfinder==2.0.8 pyparsing==2.4.2 numpy && \
    ln -sf /usr/local/bin/gcovr /usr/bin/gcovr && \
    git clone --depth 1 https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github && \
    rm -rf uldaq-env && \
    git clone --depth 1 https://github.com/jeonghanlee/open62541-env.git && \
    make -C open62541-env github && \
    rm -rf open62541-env && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
#
WORKDIR ${INSTALL_LOCATION}
#
COPY --from=builder ${INSTALL_LOCATION}/epics epics
COPY --from=builder ${INSTALL_LOCATION}/apps apps
COPY --from=builder ${INSTALL_LOCATION}/setEnv setEnv
# dash to bash (Debian/Ubuntu)
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    mkdir -p /vxboot/PVenv /vxboot/PVnames
#
SHELL [ "/bin/bash"]
ENTRYPOINT [ "" ]
#
