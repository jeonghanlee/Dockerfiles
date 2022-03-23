#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#
##
## BuildEnv docker image size : 
FROM almalinux:8.5 AS builder
#
ARG INSTALL_LOCATION=/usr/local
#
RUN export LC_CTYPE=C.UTF-8 && export LC_ALL=C.UTF-8 && \
    dnf install -y git sudo bash wget unzip make && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \\
    dnf install -y python3-pip && \
    pip3 install numpy==1.22.3
#
RUN git clone https://github.com/jeonghanlee/EPICS-env && \
    bash EPICS-env/scripts/build_epics.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/install_apps.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/als.bash
## Multi-Stages build
## Running docker image size : 2.2GB
FROM almalinux:8.5
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles
# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="alscontrols/almo8-epics"
LABEL org.label-schema.description="Alma 8 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=rk8epics alscontrols/alma8-epics"
# shellcheck will be installed through EPICS-env/scripts/install_apps.bash in builder...
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dnf update -y && \
    dnf install -y git sudo bash vi langpacks-en && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    dnf install -y java-11-openjdk python3-pip cppcheck && \
    pip3 install gcovr==5.0 flawfinder==2.0.8 pyparsing==2.4.2 numpy==1.22.3 && \
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
