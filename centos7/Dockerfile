#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.2
##
## BuildEnv docker image size : 
FROM centos:7 AS builder
#
ARG INSTALL_LOCATION=/usr/local  
#
RUN echo "LC_CTYPE=en_US.UTF-8"  >  /etc/environment && \
    echo "LC_ALL=en_US.UTF-8"    >> /etc/environment && \
    echo "LANGUAGE=en_US.UTF-8"  >> /etc/environment && \ 
    yum update -y && yum install -y git sudo bash wget unzip make && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    yum install -y python3-pip && \
    pip3 install numpy && \
    git clone https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github
#
RUN git clone https://github.com/jeonghanlee/EPICS-env && \
    bash EPICS-env/scripts/build_epics.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/install_apps.bash "${INSTALL_LOCATION}" && \
    bash EPICS-env/scripts/als.bash
## Multi-Stages build
## Running docker image size : 
FROM centos:7
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG INSTALL_LOCATION=/usr/local
ARG TZ=America/Los_Angeles
# Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/centos7-epics"
LABEL org.label-schema.description="CentOS 7 EPICS base and modules Docker Image"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=ce7epics jeonghanlee/centos7-epics"
#
ENV TZ ${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    echo "LC_CTYPE=en_US.UTF-8"  >  /etc/environment && \
    echo "LC_ALL=en_US.UTF-8"    >> /etc/environment && \
    echo "LANGUAGE=en_US.UTF-8"  >> /etc/environment && \ 
    yum update -y && \
    yum install -y git sudo bash vi langpacks-en tree && \
    git clone https://github.com/jeonghanlee/pkg_automation && \
    bash pkg_automation/pkg_automation.bash -y && \
    rm -rf pkg_automation && \
    git clone https://github.com/jeonghanlee/uldaq-env && \
    make -C uldaq-env github && \
    rm -rf uldaq-env && \
    yum install -y java-11-openjdk ShellCheck splint python3-pip cppcheck && \
    pip3 install gcovr==5.0 flawfinder==2.0.8 pyparsing==2.4.2 numpy && \
    yum clean all && rm -rf /var/cache/yum/*
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
