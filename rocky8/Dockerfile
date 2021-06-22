#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.1
##
## BuildEnv docker image size : 
FROM rockylinux/rockylinux:8.4 AS builder

ARG INSTALL_LOCATION=/usr/local

RUN export LC_CTYPE=C.UTF-8 && export LC_ALL=C.UTF-8 && \
    dnf install -y git sudo bash wget unzip make && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y

RUN git clone https://github.com/jeonghanlee/EPICS-env && \
    bash EPICS-env/scripts/build_epics.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/install_apps.bash "${INSTALL_LOCATION}"

## Multi-Stages build
## Running docker image size : 
FROM rockylinux/rockylinux:8.4
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
    dnf install -y git sudo bash vi langpacks-en && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    dnf install -y java-11-openjdk python3-pip cppcheck && \
    pip3 install flawfinder && \
    dnf clean all && rm -rf /var/cache/dnf/*
    
# repo to /entrypoint.sh
COPY entrypoint.sh .

WORKDIR ${INSTALL_LOCATION}

COPY --from=builder ${INSTALL_LOCATION}/epics epics
COPY --from=builder ${INSTALL_LOCATION}/apps apps
COPY --from=builder ${INSTALL_LOCATION}/setEnv setEnv
#
#
RUN mkdir -p /vxboot/PVenv /vxboot/PVnames

##
ENTRYPOINT [ "/entrypoint.sh" ]

