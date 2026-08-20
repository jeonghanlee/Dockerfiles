# Dockerfiles Architecture

## Scope

This document describes the repository structure, image composition, build and publication flows, platform boundary, configuration files, and validation surfaces.

**Out of scope:** Host installation procedures, Docker Hub account administration, GitHub organization policy, EPICS source maintenance, and downstream runner deployment.

## Overview

The repository defines three EPICS build images (`debian13`, `rocky8`, `rocky10`) and one documentation-rendering image (`mdbook`). Local Makefile targets and GitHub Actions workflows consume the same image definitions and validation code.

## Platform Boundary

All active EPICS images bake `EPICS_HOST_ARCH=linux-x86_64` and consume a matching prebuilt distribution tree. The published `jeonghanlee/mdbook:0.5.4` image is `linux/amd64`. Native builds and the documented host procedure therefore target `x86_64/amd64`.

## Image Composition

Each EPICS image has these functional layers:

| Layer | Contents |
|---|---|
| OS packages | Consumer IOC build toolchain and runtime libraries |
| Distribution | One sparse `EPICS-env-distribution` OS tree under `/opt/epics` |
| IOC runtime tools | `procServ` and `con` |
| Baked environment | EPICS paths, host architecture, executable path, and library path |

No EPICS source is compiled during an image build. The image carries a prebuilt EPICS tree and the toolchain needed to compile consumer IOCs.

The mdBook image uses a Rust builder stage to install the pinned `MDBOOK_VERSION`, then copies the executable into a Debian runtime image with the document rendering tools.

## Local Build Flow

```text
<image>/Dockerfile
<image>/env.conf
<image>/env.local (optional)
        |
        v
docker_builder.bash
        |
        v
docker build -> <account>/<target-name>:latest
```

`env.conf` supplies image defaults. A readable `env.local` overrides only the keys it defines for one untracked host configuration, and CLI options take final precedence.

## EPICS Image CI Flow

```text
push / pull_request / workflow_dispatch
        |
        v
.github/workflows/<image>.yml
        |
        v
.github/workflows/image.yml
        |
        +-- build and load image
        +-- run gate.bash
        `-- publish latest + DIST_VERSION
              (manual master run only)
```

The shared workflow must pass the container gate before it can publish an EPICS image.

## Documentation Flow

```text
book.toml + docs/ + fixed mdbook image
        |
        v
make docs
        |
        v
public/
        |
        v
Pages artifact -> github-pages environment
```

Pull requests build the book without deploying it. A push to `master` or a manual run on `master` builds and deploys the Pages artifact.

## Proxy Boundaries

| Network path | Configuration owner | Purpose |
|---|---|---|
| Docker daemon to registry | Docker service environment | Pull and push image manifests and layers |
| New build or container to package and source servers | Docker client proxy configuration | Supply proxy build arguments and container environment |

The daemon proxy does not supply package or Git proxy values inside a build. The Docker client configuration does not configure registry traffic from the daemon.

## Directory Structure

```text
.
|-- Makefile
|-- book.toml
|-- check_links.rb
|-- configure/
|   |-- CONFIG
|   |-- RELEASE
|   |-- CONFIG_SITE
|   |-- CONFIG_VARS
|   |-- RULES
|   |-- RULES_FUNC
|   |-- RULES_DOCKER
|   `-- RULES_VARS
|-- docs/
|   |-- README.md
|   |-- SUMMARY.md
|   |-- SETUP.md
|   |-- ARCHITECTURE.md
|   |-- MAINTENANCE.md
|   |-- IMAGE_FOOTPRINT.md
|   |-- CLOSED_DOORS.md
|   `-- milestone-69b9303.md
|-- <image>/
|   |-- Dockerfile
|   `-- env.conf
|-- .github/workflows/
|   |-- image.yml
|   |-- docs.yml
|   `-- <image>.yml
|-- docker_builder.bash
|-- gate.bash
`-- trigger.bash
```

## Active Image Set

| Image directory | Workflow | Container gate | Published version tag |
|---|---|---|---|
| `debian13/` | `debian13.yml` | Yes | `DIST_VERSION` |
| `mdbook/` | `mdbook.yml` | No | `MDBOOK_VERSION` |
| `rocky8/` | `rocky8.yml` | Yes | `DIST_VERSION` |
| `rocky10/` | `rocky10.yml` | Yes | `DIST_VERSION` |

## Configuration Scope

| Scope | File | Contents |
|---|---|---|
| Project identity | `configure/RELEASE` | Repository name, URL, and Docker account |
| Active image and documentation defaults | `configure/CONFIG_SITE` | Image lists, default image, build arguments, fixed mdBook image |
| Derived Make variables | `configure/CONFIG_VARS` | Helper paths and generated target lists |
| Image defaults | `<image>/env.conf` | Docker target name, account, build options, and build arguments |
| Per-image local override | `<image>/env.local` | Untracked override of the keys it defines |
| Make local override | `configure/*.local` | Untracked Make configuration overrides |

## Validation Surfaces

| Surface | Target | Real path |
|---|---|---|
| Bash syntax and static analysis | `make check-scripts` | Repository Bash scripts |
| Workflow YAML | `make check-workflows` | Every `.github/workflows/*.yml` file |
| Markdown character set | `make check-docs` | Every Markdown source outside `work/` |
| Local Markdown targets | `make check-links` | Relative file and image links |
| Docker build preview | `make dry-run` | Every configured image |
| EPICS container gate | `make gate.<image>` | Built EPICS image and `gate.bash` |
| Documentation render | `make docs` | Fixed mdBook image and complete source tree |
| Diff whitespace | `make check-diff` | Staged and unstaged changes |
