# Dockerfile Collections for GitLab Local Runners

This repository contains Docker image definitions for ALS GitLab runner and documentation environments. The images are built by GitHub Actions and published under the `jeonghanlee` Docker Hub account.

## Scope

This repository covers Dockerfiles, local helper scripts, and GitHub Actions workflows for the image set listed below.

**Out of scope:** Runtime application source code, EPICS module source maintenance, Docker Hub account administration, and downstream GitLab runner configuration.

## Image Set

| Image directory | Docker repository | Primary purpose |
|---|---|---|
| `debian13/` | `jeonghanlee/debian13-epics` | Debian 13 EPICS environment. |
| `rocky8/` | `jeonghanlee/rocky8-epics` | Rocky Linux 8 EPICS environment. |
| `rocky10/` | `jeonghanlee/rocky10-epics` | Rocky Linux 10 EPICS environment. |
| `mdbook/` | `jeonghanlee/mdbook` | mdbook and document rendering tools. |

## Build Data Flow

Local builds read `<image>/env.conf`, apply optional CLI overrides, and run `docker build` from the image directory.

## Makefile Workflow

Use Makefile targets for the normal repository workflow.

```bash
make help
make check
make dry-run
make dry-run.debian13
make build.debian13
make gate.debian13
make versions
```

The `make check` target runs script validation, workflow YAML parsing, markdown character checks, whitespace checks, and Docker build dry-runs for all active images.

## Direct CLI Workflow

The helper scripts remain available for direct use.

```bash
./docker_builder.bash -d -t debian13
./docker_builder.bash -t debian13 -a "BUILD_DATE=2026-05-17 BUILD_VERSION=2.6.0"
```

GitHub Actions builds each EPICS image through a shared reusable workflow, loads it into the runner, and runs the container verification gate (`gate.bash`) against it. Pull requests and master pushes build and gate only. Docker Hub publishing runs solely on a manual `workflow_dispatch` on `master`, after the gate passes, tagging `latest` and the distribution version.

An image's version is the `EPICS-env-distribution` version pinned in its `DIST_VERSION` build argument, which CI reads for the published tags. Bump it across all EPICS images at once:

```bash
make dist-version.1.2.2
```

## CI Rebuild Trigger

The `.trigger/random` file is a tracked rebuild trigger for image workflows that include `.trigger/**` in their path filters.

```bash
./trigger.bash
```

## Documentation

| Document | Purpose |
|---|---|
| `docs/README.md` | Documentation index. |
| `docs/ARCHITECTURE.md` | Repository architecture and data flow. |
| `docs/milestone.md` | Work Register for the 2026 image rework cycle. |
| `SUPPORT.md` | Maintenance procedures for adding images and updating tags. |
