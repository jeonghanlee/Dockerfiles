# Dockerfile Collections for GitLab Local Runners

This repository contains Docker image definitions for ALS GitLab runner and documentation environments. The images are built by GitHub Actions and published under the `jeonghanlee` Docker Hub account.

## Scope

This repository covers Dockerfiles, local helper scripts, and GitHub Actions workflows for the image set listed below.

**Out of scope:** Runtime application source code, EPICS module source maintenance, Docker Hub account administration, and downstream GitLab runner configuration.

## Image Set

| Image directory | Docker repository | Primary purpose |
|---|---|---|
| `debian10/` | `jeonghanlee/debian10-epics` | Debian 10 EPICS environment. |
| `debian11/` | `jeonghanlee/debian11-epics` | Debian 11 EPICS environment. |
| `debian12/` | `jeonghanlee/debian12-epics` | Debian 12 EPICS environment. |
| `debian13/` | `jeonghanlee/debian13-epics` | Debian 13 EPICS environment. |
| `rocky8/` | `jeonghanlee/rocky8-epics` | Rocky Linux 8 EPICS environment. |
| `rocky9/` | `jeonghanlee/rocky9-epics` | Rocky Linux 9 EPICS environment. |
| `rocky10/` | `jeonghanlee/rocky10-epics` | Rocky Linux 10 EPICS environment. |
| `alma8/` | `jeonghanlee/alma8-epics` | AlmaLinux 8 EPICS environment. |
| `mdbook/` | `jeonghanlee/mdbook` | Rust, mdbook, and document rendering tools. |
| `ggai/` | `jeonghanlee/ggai` | Python Google Generative AI tooling. |

## Build Data Flow

Local builds read `<image>/env.conf`, apply optional CLI overrides, and run `docker build` from the image directory.

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
| `docs/repository-refactor-plan.md` | Refactor scope, phases, safety rules, and verification gates. |
| `SUPPORT.md` | Maintenance procedures for adding images and updating tags. |
