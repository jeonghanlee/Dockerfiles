#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.2
##
FROM rust:slim-bookworm
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles
## Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/mdbook"
LABEL org.label-schema.description="Rust with mdbook"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=mdbook jeonghanlee/mdbook /bin/bash"
#
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt update -y && \
    apt upgrade -y && \
    cargo install mdbook@0.4.48 && \
    apt clean && \
    rm -rf /var/lib/apt/* && \
    rm -rf /var/lib/dpkg/*
#
SHELL [ "/bin/bash"]
ENTRYPOINT [ "" ]
#
