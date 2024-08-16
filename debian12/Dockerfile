#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3
##
## BuildEnv docker image size : GB
FROM amd64/debian:bookworm-slim AS builder
#
ARG INSTALL_LOCATION=/usr/local
#
RUN apt update -y && \
    apt install -y  git sudo bash wget unzip make && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    git clone https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github
#
RUN git clone https://github.com/jeonghanlee/EPICS-env && \
    bash EPICS-env/scripts/build_epics.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/install_apps.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/als.bash
# Multi-Stages build
# Running docker image size : GB
FROM amd64/debian:bookworm-slim
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles
## Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/debian12-epics"
LABEL org.label-schema.description="Debian 12 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=deb12epics jeonghanlee/debian12-epics /bin/bash"
#
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt update -y && \
    apt install -y git sudo bash vim openjdk-17-jre-headless&& \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    git clone https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github && \
    rm -rf uldaq-env && \
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
