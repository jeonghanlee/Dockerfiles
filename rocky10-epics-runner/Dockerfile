#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.0
#
# Supervised runtime image (variant A): the development image plus the
# ioc-runner container supervision layer. procServ and con ship from the base;
# this image adds ioc-runner and an s6-svscan entry point so an IOC runs under
# supervision inside a systemd-less container. The same layer applies to a slim
# runtime base later (variant B).
ARG IMAGE_VERSION=1.0.1
FROM jeonghanlee/rocky10-epics:${IMAGE_VERSION}

ARG RUNNER_VERSION=1.4.0
ARG RUNNER_REPO=https://github.com/jeonghanlee/epics-ioc-runner.git
ARG BUILD_DATE
ARG BUILD_VERSION

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.name="jeonghanlee/rocky10-epics-runner"
LABEL org.label-schema.description="Rocky Linux 10 EPICS image with the ioc-runner container supervision layer"
LABEL org.label-schema.url="https://github.com/jeonghanlee/Dockerfiles/"
LABEL org.label-schema.version=$BUILD_VERSION
LABEL epics.runner-version=$RUNNER_VERSION

# ioc-runner supervision layer: install the runner from the pinned tag and run
# its container setup - the service account, group, configuration directory,
# and scan directory, with no sudoers entry, unit template, or log rotation.
# The setup step also installs the CLI, since its STEP 7 runs in every mode.
RUN git clone --depth 1 --branch "${RUNNER_VERSION}" "${RUNNER_REPO}" /tmp/runner && \
    /bin/bash -p /tmp/runner/bin/setup-system-infra.bash --container && \
    printf '%s %s %s %s\n' epics-ioc-runner "${RUNNER_REPO}" "$(git -C /tmp/runner rev-parse HEAD)" "$(date -u +%FT%TZ)" >> /etc/epics-bake.manifest && \
    rm -rf /tmp/runner

# Entry point: the scan directory is created at container start (a build-time
# copy under /run does not survive a tmpfs mount) and s6-svscan runs as PID 1.
# The container runs as root; ioc-runner refuses without a live s6-svscan.
RUN printf '%s\n' \
      '#!/bin/bash' \
      'set -eu' \
      'mkdir -p /run/s6-procserv' \
      'exec s6-svscan /run/s6-procserv' \
      > /usr/local/bin/s6-svscan-entrypoint && \
    chmod 0755 /usr/local/bin/s6-svscan-entrypoint

ENTRYPOINT ["/usr/local/bin/s6-svscan-entrypoint"]
