# Dockerfiles Architecture

## Scope

This document describes the repository structure, build flow, configuration files, and validation surfaces for the Docker image definitions.

**Out of scope:** Docker Hub account administration, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Overview

The repository defines a maintained set of Docker images for ALS GitLab runner, container IOC, and test environments. The three EPICS images (`debian13`, `rocky8`, `rocky10`) consume a prebuilt EPICS environment from `EPICS-env-distribution`; `mdbook` is a separate documentation-rendering image. Local helper scripts, Makefile targets, and GitHub Actions workflows share the same per-image directory configuration.

## Image Composition

Each EPICS image is single-stage and layered as:

| Layer | Contents |
|---|---|
| OS packages | Build toolchain plus the runtime libraries the shipped tree links, pruned to what the distribution and in-container consumer IOC builds need. |
| Distribution | A sparse fetch of one `EPICS-env-distribution` OS tree (`<DIST_VERSION>/<os>/<epics-version>`) placed under `/opt/epics`, with a bake manifest recording component commits. |
| IOC runtime tools | `procServ` and `con`, built in-layer with a transient autotools set that is removed in the same layer. |
| Baked environment | `EPICS_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH`, `PATH`, `LD_LIBRARY_PATH` set via `ENV`, so the environment is present without sourcing. |

No EPICS source is compiled during the image build; the consumer build toolchain ships in the image because runner jobs compile IOCs in-container.

## Build Flow

Local build:

```text
<image>/Dockerfile + <image>/env.conf
        |
        v
docker_builder.bash  (reads env.conf for the image name and build options)
        |
        v
docker build  ->  <account>/<image>-epics:latest
```

CI build (EPICS images), a thin per-OS caller into one reusable workflow:

```text
push / pull_request / workflow_dispatch
        |
        v
.github/workflows/<image>.yml  (path filters, concurrency)
        |
        v
.github/workflows/image.yml  (reusable, workflow_call)
        |
        +-- build and load the image into the runner daemon
        +-- run gate.bash against the loaded image
        +-- publish latest + <DIST_VERSION>
              (workflow_dispatch on master only, after the gate passes)
```

## Directory Structure

```text
.
|-- Makefile
|-- configure/
|   |-- CONFIG
|   |-- RELEASE
|   |-- CONFIG_SITE
|   |-- CONFIG_VARS
|   |-- RULES
|   |-- RULES_FUNC
|   |-- RULES_DOCKER
|   `-- RULES_VARS
|-- <image>/
|   |-- Dockerfile
|   `-- env.conf
|-- .github/workflows/
|   |-- image.yml
|   `-- <image>.yml
|-- docker_builder.bash
|-- gate.bash
`-- trigger.bash
```

## Active Image Set

| Image directory | Workflow | EPICS image (gated + versioned) |
|---|---|---|
| `debian13/` | `.github/workflows/debian13.yml` | Yes |
| `mdbook/` | `.github/workflows/mdbook.yml` | No |
| `rocky8/` | `.github/workflows/rocky8.yml` | Yes |
| `rocky10/` | `.github/workflows/rocky10.yml` | Yes |

The EPICS images call the shared `.github/workflows/image.yml`; `mdbook` has its own standalone workflow.

## Configuration Scope

| Scope | File | Contents |
|---|---|---|
| Project identity | `configure/RELEASE` | Repository name, project URL, Docker account. |
| Active image list | `configure/CONFIG_SITE` | Image directories, release image directories, default image. |
| Derived Make variables | `configure/CONFIG_VARS` | Tool paths, workflow list, generated target lists. |
| Image defaults | `<image>/env.conf` | Local Docker target name, account, build options, build args. |
| Local overrides | `configure/*.local` | Untracked site-specific Makefile overrides. |

## Validation Surfaces

| Surface | Make target | Direct command |
|---|---|---|
| Bash syntax | `make check-scripts` | `bash -n docker_builder.bash gate.bash trigger.bash` |
| Bash static analysis | `make check-scripts` | `shellcheck -S warning docker_builder.bash gate.bash trigger.bash` |
| Workflow YAML parse | `make check-workflows` | `ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p) }' .github/workflows/*.yml` |
| Docker build preview | `make dry-run` | `./docker_builder.bash -d -t <image>` |
| Container gate | `make gate.<image>` | `docker run --rm -v $PWD/gate.bash:/gate.bash:ro <image> bash /gate.bash` |
| Diff whitespace | `make check-diff` | `git diff --check` |
