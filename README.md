# Dockerfile Collections for the GitLab Local Runners
[![Debian 12 Bookworm](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian12.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian12.yml)
[![Rocky Linux 9](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky9.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky9.yml)
[![Rocky Linux 8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml)
[![Alma8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml)

[![Rust with mdbook](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/mdbook.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/mdbook.yml)i

For saving valuable resources (time, electricity, computing power, and so on), these collections will be used to generate Linux Images with the EPICS environment with full libraries and mdbook with rust for the gitlab runner.

The following example commands are good for building its docker image locally. And all docker images are built through the Github Actions. The Docker images are hosted at https://hub.docker.com/repositories/jeonghanlee

## Release Procedure

* Relaese the new version. Check the latest one at https://hub.docker.com/repository/docker/jeonghanlee/rocky8-epics

```bash
./release.bash v1.x.x
```

* Everything works within github action, release latest one

```bash
./release.bash
```

## Debian 12 + EPICS

```bash
bash docker_builder.bash -t debian11
```

## Rocky 9 + EPICS

```bash
bash docker_builder.bash -t rocky9
```

## Rocky 8 + EPICS

```bash
bash docker_builder.bash -t rocky8
```

## Run Locally

One needs to add `/bin/bash` as `ENTRYPOINT`.

```bash
$  docker run -it jeonghanlee/centos7-epics /bin/bash

root@d15155bd0e42 local]# source /usr/local/setEnv 
Set the EPICS Environment as follows:
THIS Source NAME    : setEpicsEnv.bash
THIS Source PATH    : /usr/local/epics/R7.0.5
EPICS_BASE          : /usr/local/epics/R7.0.5/base
EPICS_HOST_ARCH     : linux-x86_64
EPICS_MODULES       : /usr/local/epics/R7.0.5/modules
PATH                : /usr/local/epics/R7.0.5/base/bin/linux-x86_64:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LD_LIBRARY_PATH     : /usr/local/epics/R7.0.5/base/lib/linux-x86_64

Enjoy Everlasting EPICS!
```

## The EPICS environment and others

The EPICS environment and others path can be defined via a shell script located in `${INSTALL_LOCATION}`. Its default location is `/usr/local`

```bash
source /usr/local/setEnv
```

The additional application(s) (for example, `pmd`) is installed in `/usr/local/apps` path.

## Force Docker to use `amd64` instead of `aarch64` on MacOS M1

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```
