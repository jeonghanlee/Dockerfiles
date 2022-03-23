# Dockerfile Collections for the GitLab Local Runners
[![Debian 11 Bullseye](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian11.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian11.yml)
[![Debian10](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian10.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian10.yml)
[![Rocky8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml)
[![Alma8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml)
[![CentOS7](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/centos7.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/centos7.yml)
[![Scientific Linux 7](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/sl7.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/sl7.yml)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/adfd1fd512cd4dfda0635ced97bb9a71)](https://www.codacy.com/gh/jeonghanlee/Dockerfiles/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jeonghanlee/Dockerfiles&amp;utm_campaign=Badge_Grade)

For saving valuable resources (time, electricity, computing power, and so on), these collections will be used to generate Linux Images with the EPICS environment with full libraries for the gitlab runner. The generated image size is big, because they should contain almost all libraries for the EPICS and other applications.

The following example commands are good for building its docker image locally. And all docker images are built through the Github Actions. The Docker images are hosted at https://hub.docker.com/orgs/alscontrols

## Release Procedure

* Relaese the new version. Check the latest one at https://hub.docker.com/repository/docker/alscontrols/rocky8-epics

```bash
./release.bash v1.x.x
```

* Everything works within github action, release latest one

```bash
./release.bash
```

## Debian 11 + EPICS

```bash
bash docker_builder.bash -t debian11
```

## Debian 10 + EPICS

```bash
bash docker_builder.bash -t debian10
```

## Rocky 8 + EPICS

```bash
bash docker_builder.bash -t rocky8
```

## Alma 8 + EPICS

```bash
bash docker_builder.bash -t alma8
```

## CentOS7 + EPICS

```bash
bash docker_builder.bash -t centos7
```

## Scientific Linux 7 + EPICS

```bash
bash docker_builder.bash -t sl7
```

## Use within the Gitlab Runnner

These images are optimized for the Gitlab Runner. The following example `.gitlab-ci.yml` shows how to integrate them

```bash
build-centos7:
    stage: build
    tags:
        - centos7-epics
    
    script:
        - source /usr/local/setEnv
        - shellcheck -V
        - git ls-files --exclude='*.bash' --ignored | xargs shellcheck  || echo "No script found!"
        - caget -h

test-centos7:
    stage: test
    needs: [ "build-centos7" ]
    tags:
        - centos7-epics
    script:
        - source /usr/local/setEnv
        - bash ${CI_PROJECT_DIR}/test.bash

build-debian10:
    stage: build
    tags:
        - debian10-epics
    script:
        - source /usr/local/setEnv
        - shellcheck -V
        - git ls-files --exclude='*.bash' --ignored | xargs shellcheck  || echo "No script found!"
        - caget -h

test-debian10:
    stage: test
    needs: [ "build-debian10" ]
    tags:
        - debian10-epics
    script:
        - source /usr/local/setEnv
        - bash ${CI_PROJECT_DIR}/test.bash

build-rocky8:
    stage: build
    tags:
        - rocky8-epics
    script:
        - source /usr/local/setEnv
        - caget -h

test-rocky8:
    stage: test
    needs: [ "build-rocky8" ]
    tags:
        - rocky8-epics
    script:
        - source /usr/local/setEnv
        - bash ${CI_PROJECT_DIR}/test.bash
        
```

## Run Locally

One needs to add `/bin/bash` as `ENTRYPOINT`.

```bash
$  docker run -it alscontrols/centos7-epics /bin/bash

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
