# Dockerfile Collections for GitLab Local Runners

This repository contains Docker image definitions for ALS GitLab runner and documentation environments. The images are built by GitHub Actions and published under the `jeonghanlee` Docker Hub account.

## Scope

This repository covers Dockerfiles, local helper scripts, and GitHub Actions workflows for the image set listed below.

**Out of scope:** Runtime application source code, EPICS module source maintenance, Docker Hub account administration, and downstream GitLab runner configuration.

## Image Set

| Image directory | Docker repository | Primary purpose |
|---|---|---|
| `debian12/` | `jeonghanlee/debian12-epics` | Debian 12 EPICS environment. |
| `debian13/` | `jeonghanlee/debian13-epics` | Debian 13 EPICS environment. |
| `rocky8/` | `jeonghanlee/rocky8-epics` | Rocky Linux 8 EPICS environment. |
| `rocky9/` | `jeonghanlee/rocky9-epics` | Rocky Linux 9 EPICS environment. |
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
make release.dry-run
```

The `make check` target runs script validation, workflow YAML parsing, markdown character checks, whitespace checks, and Docker build dry-runs for all active images.

## Direct CLI Workflow

The helper scripts remain available for direct use.

```bash
./docker_builder.bash -d -t debian13
./docker_builder.bash -t debian13 -a "BUILD_DATE=2026-05-17 BUILD_VERSION=2.5.1"
```

GitHub Actions workflows build only the image directory relevant to the workflow. Pull requests build without Docker Hub login or push. Push events to `master` log in to Docker Hub and publish the configured `DOCKER_TAG`.

Release tag updates are applied to active release workflows:

```bash
./release.bash v2.5.1
./release.bash -f
```

The `-f` form selects `latest` without an interactive prompt.

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
| `docs/repository-refactor-plan.md` | Refactor scope, phases, safety rules, and verification gates. |
| `SUPPORT.md` | Maintenance procedures for adding images and updating tags. |
