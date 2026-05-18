# Dockerfiles Architecture

## Scope

This document describes the repository structure, build flow, configuration files, and validation surfaces for the Docker image definitions.

**Out of scope:** Docker Hub account administration, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Overview

The repository defines a maintained set of Docker images for ALS GitLab runner and documentation environments. Local helper scripts and Makefile targets share the same image directory configuration used by GitHub Actions workflows.

## Build Flow

```text
image directory
  |
  +-- Dockerfile
  +-- env.conf
        |
        v
docker_builder.bash
        |
        v
docker build from image directory
```

GitHub Actions follows the same image-directory boundary:

```text
push or pull request
        |
        v
.github/workflows/<image>.yml
        |
        v
docker/build-push-action
        |
        +-- pull request: build only
        +-- master push: build and push configured tag
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
|   `-- <image>.yml
|-- docker_builder.bash
|-- release.bash
`-- trigger.bash
```

## Active Image Set

| Image directory | Workflow | Release tag updates |
|---|---|---|
| `debian12/` | `.github/workflows/debian12.yml` | Yes |
| `debian13/` | `.github/workflows/debian13.yml` | Yes |
| `mdbook/` | `.github/workflows/mdbook.yml` | No |
| `rocky8/` | `.github/workflows/rocky8.yml` | Yes |
| `rocky9/` | `.github/workflows/rocky9.yml` | Yes |
| `rocky10/` | `.github/workflows/rocky10.yml` | Yes |

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
| Bash syntax | `make check-scripts` | `bash -n docker_builder.bash release.bash trigger.bash` |
| Bash static analysis | `make check-scripts` | `shellcheck -S warning docker_builder.bash release.bash trigger.bash` |
| Workflow YAML parse | `make check-workflows` | `ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p) }' .github/workflows/*.yml` |
| Docker build preview | `make dry-run` | `./docker_builder.bash -d -t <image>` |
| Release tag preview | `make release.dry-run` | `./release.bash -n -f` |
| Diff whitespace | `make check-diff` | `git diff --check` |
