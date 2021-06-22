# Dockerfile Collections for the GitLab Local Runners
[![Debian10](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian10.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian10.yml)
[![Rocky8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml)
[![CentOS7](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/centos7.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/centos7.yml)

For saving valuable resouces (time, electricity, computing power, and so on), this collections will be used to generate Linux Images with the EPICS environment with full libraries for the gitlab runner. The image size is still big. However, these images should contains almost all libraries for the EPICS application.

The following example commands are good for building its docker image locally. The all docker images are built through the Github Actions.

## Debian 10 + EPICS

```bash
bash docker_builder.bash -t debian10
```

## Rocky 8 + EPICS

```bash
bash docker_builder.bash -t rocky8
```

## CentOS7 + EPICS

```bash
bash docker_builder.bash -t centos7
```

## Run Locally

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

build-debian10:
    stage: build
    tags:
        - debian10-epics
    script:
        - source /usr/local/setEnv
        - shellcheck -V
        - git ls-files --exclude='*.bash' --ignored | xargs shellcheck  || echo "No script found!"
        - caget -h

build-rock8:
    stage: build
    tags:
        - rocky8-epics
    script:
        - source /usr/local/setEnv
        - caget -h

```


## The EPICS environment and others

The EPICS environment and others path can be defined via a shell script located in `${INSTALL_LOCATION}`. Its default location is `/usr/local`

```bash
source /usr/local/setEnv
```

The additional application(s) (for example, `pmd`) is installed in `/usr/local/apps` path. 

