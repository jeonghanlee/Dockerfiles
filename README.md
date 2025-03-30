# Dockerfile Collections for the GitLab Local Runners
[![Debian 12 Bookworm](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian12.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/debian12.yml)
[![Rocky Linux 8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky8.yml)
[![Rust with mdbook](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/mdbook.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/mdbook.yml)
[![Rocky Linux 9](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky9.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/rocky9.yml)
[![Alma8](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml/badge.svg)](https://github.com/jeonghanlee/Dockerfiles/actions/workflows/alma8.yml)

To save valuable resources (time, electricity, computing power, etc.), the configurations in this repository are used to generate Linux docker images. These images contain the EPICS environment (including full libraries) and mdbook with the Rust, specifically for use with the ALS GitLab runners.

You can use the following example commands to build the Docker image locally. However, all official Docker images are built automatically via GitHub Actions and are hosted on Docker Hub: https://hub.docker.com/repositories/jeonghanlee

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

## Force Docker to use `amd64` instead of `aarch64` on MacOS M1

```bash
export DOCKER_DEFAULT_PLATFORM=linux/amd64
```
