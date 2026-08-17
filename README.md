# Dockerfile Collections for GitLab Local Runners

This repository contains Docker image definitions for ALS GitLab runner, container IOC, and test environments. The EPICS images consume a prebuilt EPICS environment from `EPICS-env-distribution` and are built by GitHub Actions under the `jeonghanlee` Docker Hub account.

## Scope

This repository covers Dockerfiles, local helper scripts, and GitHub Actions workflows for the image set listed below.

**Out of scope:** Runtime application source code, EPICS module source maintenance, Docker Hub account administration, and downstream GitLab runner configuration.

## Image Set

| Image directory | Docker repository | Primary purpose |
|---|---|---|
| `debian13/` | `jeonghanlee/debian13-epics` | Debian 13 EPICS environment. |
| `rocky8/` | `jeonghanlee/rocky8-epics` | Rocky Linux 8.10 EPICS environment. |
| `rocky10/` | `jeonghanlee/rocky10-epics` | Rocky Linux 10.2 EPICS environment. |
| `mdbook/` | `jeonghanlee/mdbook` | mdbook and document rendering tools. |

## Build Data Flow

Each EPICS image consumes a prebuilt `EPICS-env-distribution` tree, bakes the environment via `ENV`, and carries `procServ`/`con` plus the consumer build toolchain. Local builds read `<image>/env.conf`, apply optional CLI overrides, and run `docker build` from the image directory. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the layer breakdown and CI topology.

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
```

Build args are optional and passed through with `-a`. Substitute real values
for the angle-bracket fields below; they are placeholders, not literals.

```bash
./docker_builder.bash -t debian13 -a "BUILD_DATE=<YYYY-MM-DD> BUILD_VERSION=<version>"
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
| `docs/milestone-69b9303.md` | Work Register for the remaining master work after the 1.2.2 release. |
| `docs/CLOSED_DOORS.md` | Examined candidates deliberately left unchanged. |
| `docs/IMAGE_FOOTPRINT.md` | Image size axes, measuring commands, and history. |
| `SUPPORT.md` | Maintenance procedures: add an image, bump the distribution version, run the gate. |
