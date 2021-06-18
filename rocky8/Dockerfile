#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1
##
## BuildEnv docker image size : 
FROM rockylinux/rockylinux:8.4-rc1 AS builder

ENV WorkPath /home/EPICS
ARG INSTALL_LOCATION=/usr/local

RUN export LC_CTYPE=C.UTF-8 &&\
    export LC_ALL=C.UTF-8 &&\
    dnf install -y git sudo bash && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    git clone https://github.com/jeonghanlee/EPICS-env && \ 
    echo "INSTALL_LOCATION:=${INSTALL_LOCATION}" > EPICS-env/configure/CONFIG_SITE.local &&\
    make -C EPICS-env/ distclean && \
    make -C EPICS-env/ init && \
    make -C EPICS-env/ conf && \
    make -C EPICS-env/ patch && \
    make -C EPICS-env/ build && \
    make -C EPICS-env/ install && \
    make -C EPICS-env/ symlinks.modules

## Multi-Stages build
## Running docker image size : 
FROM rockylinux/rockylinux:8.4-rc1
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles

# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky8-epics"
LABEL org.label-schema.description="Rocky 8 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/EPICS-env/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=epics jeonghanlee/rocky8-epics"

### YOUR TIME ZONE
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    dnf update -y && \
    dnf install -y git sudo bash vi langpacks-en&& \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y

WORKDIR ${INSTALL_LOCATION}
COPY --from=builder ${INSTALL_LOCATION} .
##
ENTRYPOINT ["/bin/bash"]

