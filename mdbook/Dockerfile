#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.0
##
FROM rust:slim-bookworm AS builder
#
ARG MDBOOK_VERSION="0.4.52"
#
RUN cargo install mdbook --version ${MDBOOK_VERSION} --locked

FROM debian:bookworm-slim
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG TZ=America/Los_Angeles
## Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/mdbook"
LABEL org.label-schema.description="mdbook and PDF generation tools"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=mdbook jeonghanlee/mdbook /bin/bash"
#
ENV TZ=${TZ}
ENV DEBIAN_FRONTEND=noninteractive
#
COPY --from=builder /usr/local/cargo/bin/mdbook /usr/local/bin/mdbook
#
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    perl \
    inkscape \
    ghostscript \
    qrencode \
    fonts-liberation && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "" ]
#
