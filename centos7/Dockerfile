#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1
##
## BuildEnv docker image size : 
FROM centos:7 AS builder

ENV WorkPath /home/EPICS
ARG INSTALL_LOCATION=/usr/local

RUN echo "LC_CTYPE=en_US.UTF-8"  >  /etc/environment && \
    echo "LC_ALL=en_US.UTF-8"    >> /etc/environment && \
    echo "LANGUAGE=en_US.UTF-8"  >> /etc/environment && \ 
    yum install -y git sudo bash langpacks-en && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    git clone https://github.com/jeonghanlee/EPICS-env && \ 
    echo "INSTALL_LOCATION:=${INSTALL_LOCATION}" > CONFIG_SITE.local && \
    make -s -C EPICS-env/ init && \
    make -s -C EPICS-env/ conf && \
    make -s -C EPICS-env/ patch && \
    make -s -C EPICS-env/ print-INSTALL_LOCATION_EPICS > ${INSTALL_LOCATION}/.epics_path && \
    make -s -C EPICS-env/ print-INSTALL_LOCATION_BASE  > ${INSTALL_LOCATION}/.base_path  && \
    make -s -C EPICS-env/ print-INSTALL_LOCATION_MODS  > ${INSTALL_LOCATION}/.modules_path  && \
    make -s -C EPICS-env/ print-PATH_NAME_EPICS        > ${INSTALL_LOCATION}/.epics_vers && \
    echo ${INSTALL_LOCATION}/epics/R$(cat ${INSTALL_LOCATION}/.epics_vers) > ${INSTALL_LOCATION}/.symlink_epics_path && \
    make -s -C EPICS-env/ build && \
    make -s -C EPICS-env/ install && \
    make -s -C EPICS-env/ symlinks.modules && \
    mkdir -p $(cat ${INSTALL_LOCATION}/.symlink_epics_path) && \
    ln -snf $(cat ${INSTALL_LOCATION}/.base_path)    $(cat ${INSTALL_LOCATION}/.symlink_epics_path)/base && \
    ln -snf $(cat ${INSTALL_LOCATION}/.modules_path) $(cat ${INSTALL_LOCATION}/.symlink_epics_path)/modules

## Multi-Stages build
## Running docker image size : 
FROM centos:7
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles

# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/centos7-epics"
LABEL org.label-schema.description="CentOs 7EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/EPICS-env/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=epics jeonghanlee/centos7-epics"

### YOUR TIME ZONE
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    yum update -y && \
    yum install -y git sudo bash vi langpacks-en && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y

WORKDIR ${INSTALL_LOCATION}
COPY --from=builder ${INSTALL_LOCATION} .
RUN mkdir -p /vxboot/PVenv /vxboot/PVnames


##
ENTRYPOINT ["/bin/bash"]

