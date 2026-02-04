#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.0.3
##
FROM rust:slim-bookworm
LABEL maintainer="Jeong Han Lee <jeonghan.lee@gmail.com>"
#
ARG BUILD_DATE
ARG BUILD_VERSION
ARG MDBOOK_VERSION="0.4.52"
ARG TZ=America/Los_Angeles
## Labels.
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/mdbook"
LABEL org.label-schema.description="Rust with mdbook and PDF generation tools"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL org.label-schema.docker.cmd="docker run -it --rm --name=mdbook jeonghanlee/mdbook /bin/bash"
#
ENV TZ=${TZ}
ENV DEBIAN_FRONTEND=noninteractive

# Installation Logic
# 1. Configure Timezone
# 2. Update and Install Dependencies (Core, Graphics, Fonts)
#    - Using --no-install-recommends to keep the image slim
#    - Included librsvg2-bin and imagemagick as discussed previously
# 3. Install mdbook via Cargo
# 4. Clean up apt cache to reduce image size
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
    git \
    perl \
    inkscape \
    ghostscript \
    qrencode \
    fonts-noto-cjk \
    fonts-liberation && \
    cargo install mdbook --version ${MDBOOK_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

SHELL [ "/bin/bash", "-c" ]
ENTRYPOINT [ "" ]
#
