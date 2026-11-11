# Dockerfiles Architecture

## Scope

This document describes the repository structure, image composition, build and publication flows, platform boundary, configuration files, and validation surfaces.

**Out of scope:** Host installation procedures, Docker Hub account administration, GitHub organization policy, EPICS source maintenance, and downstream runner deployment.

## Overview

The repository defines 18 EPICS images and one documentation-rendering image (`mdbook`). The EPICS images form six OS sets (`debian12`, `debian13`, `rocky8`, `rocky10`, `ubuntu24`, `ubuntu26`) of three images each: a development image (`<os>-epics`), a supervised runtime image (`<os>-epics-runner`), and a toolchain-free runtime image with a baked IOC (`<os>-epics-slim`). Every version of the 18 images is one line of `configure/VERSIONS`. Local Makefile targets and GitHub Actions workflows consume the same image definitions, versions, and validation code.

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

No EPICS source is compiled during an image build. The development image carries a prebuilt EPICS tree and the toolchain needed to compile consumer IOCs.

The runner image is the development image of the same OS set plus the supervision layer: `epics-ioc-runner` installed in container mode and `s6-svscan` as the entry point. The slim image compiles an IOC in a build stage on the development image, copies the EPICS tree, `procServ`, `con`, and the IOC into a toolchain-free final stage, and installs the supervision layer in that stage; its `EPICS_PATH` is `/opt/epics/current`, a link to the versioned tree. [CONTAINER_RUNTIME.md](CONTAINER_RUNTIME.md) describes the runtime roles.

The mdBook image uses a Rust builder stage to install the pinned `MDBOOK_VERSION`, then copies the executable into a Debian runtime image with the document rendering tools.

## Local Build Flow

```text
configure/VERSIONS
<image>/Dockerfile
<image>/env.conf
<image>/env.local (optional)
        |
        v
docker_builder.bash
        |
        v
docker build -> <account>/<target-name>:latest and :<IMAGE_VERSION>
```

`docker_builder.bash` passes each `configure/VERSIONS` key that the Dockerfile declares as a build argument, then the `env.conf` values. A readable `env.local` overrides only the keys it defines for one untracked host configuration, and CLI options take final precedence. The local `<IMAGE_VERSION>` tag lets a runner or slim build use the development image built just before it.

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
        +-- build the base image (runner and slim only)
        +-- build and load image
        `-- run gate.bash
```

The build arguments come from `docker_builder.bash -b`, which reads `configure/VERSIONS`. A runner or slim workflow passes `base_dir`, so its job builds the development image first and the runner or slim image builds on that local image; the job does not need the base tag on Docker Hub. The per-OS workflows carry no publish step, so they can be dispatched to re-run the build and gate without publishing.

Publishing is separate and owner-run:

```text
workflow_dispatch (owner, version input)
        |
        v
.github/workflows/release.yml
        |
        +-- six development images  (release-image.yml each)
        `-- 12 runner and slim images, after all six succeed
                |
                +-- skip the build when the version tag exists
                +-- build, gate, push the version tag
                `-- copy the version manifest to latest
```

`release.yml` publishes all 18 images at the `IMAGE_VERSION` of `configure/VERSIONS` and labels each image with its source commit. [RELEASE.md](RELEASE.md) is the release procedure, and `make release-status` and `make release-verify` read its state. `publish.yml` publishes one image chosen by its `image_dir` input; it replaces the tags and adds no revision label.

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
|-- check_versions.bash
|-- configure/
|   |-- CONFIG
|   |-- RELEASE
|   |-- CONFIG_SITE
|   |-- CONFIG_VARS
|   |-- VERSIONS
|   |-- RULES
|   |-- RULES_FUNC
|   |-- RULES_DOCKER
|   `-- RULES_VARS
|-- docs/
|   |-- README.md
|   |-- SUMMARY.md
|   |-- SETUP.md
|   |-- ARCHITECTURE.md
|   |-- CONTAINER_RUNTIME.md
|   |-- MAINTENANCE.md
|   |-- RELEASE.md
|   |-- IMAGE_FOOTPRINT.md
|   |-- CLOSED_DOORS.md
|   `-- milestone-69b9303.md
|-- <image>/
|   |-- Dockerfile
|   `-- env.conf
|-- .github/workflows/
|   |-- image.yml
|   |-- release.yml
|   |-- release-image.yml
|   |-- publish.yml
|   |-- mdbook.yml
|   |-- docs.yml
|   `-- <image>.yml
|-- docker_builder.bash
|-- gate.bash
|-- release.bash
`-- trigger.bash
```

## Active Image Set

| Image directory | Workflow | Container gate | Published version tag |
|---|---|---|---|
| `<os>/` | `<os>.yml` | 12 checks | `IMAGE_VERSION` |
| `<os>-epics-runner/` | `<os>-epics-runner.yml` | 13 checks, supervised mode | `IMAGE_VERSION` |
| `<os>-epics-slim/` | `<os>-epics-slim.yml` | 13 checks, supervised mode | `IMAGE_VERSION` |
| `mdbook/` | `mdbook.yml` | No | `MDBOOK_VERSION` |

`<os>` is one of `debian12`, `debian13`, `rocky8`, `rocky10`, `ubuntu24`, and `ubuntu26`. The supervised mode runs the gate under an explicit `bash` entry point with `GATE_RUNNER=1`, which adds the supervision checks G11 and G12; the slim image skips the G8 linkage check, since it carries no `readelf`.

## Configuration Scope

| Scope | File | Contents |
|---|---|---|
| Project identity | `configure/RELEASE` | Repository name, URL, and Docker account |
| Image versions | `configure/VERSIONS` | Distribution, image, EPICS base, and component versions of the 18 EPICS images |
| Active image and documentation defaults | `configure/CONFIG_SITE` | Image lists, held version keys, default image, build arguments, fixed mdBook image |
| Derived Make variables | `configure/CONFIG_VARS` | Helper paths and generated target lists |
| Image defaults | `<image>/env.conf` | Docker target name, account, build options, and build arguments |
| Per-image local override | `<image>/env.local` | Untracked override of the keys it defines |
| Make local override | `configure/*.local` | Untracked Make configuration overrides |

## Validation Surfaces

| Surface | Target | Real path |
|---|---|---|
| Bash syntax and static analysis | `make check-scripts` | Repository Bash scripts |
| Workflow YAML | `make check-workflows` | Every `.github/workflows/*.yml` file |
| Version source | `make check-versions` | `configure/VERSIONS`, the 18 EPICS Dockerfiles, and their workflows |
| Release state | `make release-status`, `make release-verify` | Git, GitHub Actions, and Docker Hub state of one release |
| Markdown character set | `make check-docs` | Every Markdown source outside `work/` |
| Local Markdown targets | `make check-links` | Relative file and image links |
| Docker build preview | `make dry-run` | Every configured image |
| EPICS container gate | `make gate.<image>` | Built EPICS image and `gate.bash` |
| Documentation render | `make docs` | Fixed mdBook image and complete source tree |
| Diff whitespace | `make check-diff` | Staged and unstaged changes |
