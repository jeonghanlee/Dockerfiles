# Docker Image Definitions for EPICS Build Environments

This repository maintains Docker image definitions for ALS GitLab runners, container IOC development, test environments, and mdBook rendering. The EPICS images consume a prebuilt `EPICS-env-distribution` tree and publish under the `jeonghanlee` Docker Hub account.

## Scope

This repository covers Dockerfiles, local build helpers, validation gates, documentation, and GitHub Actions workflows for the active image set.

**Out of scope:** Runtime application source, EPICS module source maintenance, Docker Hub account administration, and downstream GitLab runner configuration.

## Image Set

| Image directory | Docker repository | Primary purpose |
|---|---|---|
| `debian13/` | `jeonghanlee/debian13-epics` | Debian 13 EPICS environment |
| `rocky8/` | `jeonghanlee/rocky8-epics` | Rocky Linux 8.10 EPICS environment |
| `rocky10/` | `jeonghanlee/rocky10-epics` | Rocky Linux 10.2 EPICS environment |
| `mdbook/` | `jeonghanlee/mdbook` | mdBook and document rendering tools |

The verified local host scope is Debian 13 on `x86_64/amd64`. Start with [docs/SETUP.md](docs/SETUP.md) for package installation, Docker access, proxy configuration, and the first build.

## Makefile Workflow

Use Makefile targets for the normal repository workflow:

```bash
make help
make check
make build.debian13
make gate.debian13
make docs
make versions
```

`make check` validates repository sources and previews every configured image build. `make docs` renders the mdBook site into `public/` with `jeonghanlee/mdbook:0.5.4`.

## Direct CLI Workflow

The image helper remains available for a direct dry-run:

```bash
./docker_builder.bash -d -t debian13
```

Build arguments are optional CLI overrides:

```bash
./docker_builder.bash -t debian13 -a "BUILD_DATE=<YYYY-MM-DD> BUILD_VERSION=<version>"
```

Local image defaults come from `<image>/env.conf`; untracked `<image>/env.local` files override those defaults for one host.

## Continuous Integration

The three EPICS image workflows call the shared `image.yml`, load each image, and run the container gate. A manual run on `master` publishes `latest` and the pinned `DIST_VERSION` only after the gate passes.

The mdBook image workflow builds on pushes and pull requests. A manual run on `master` publishes `latest` and the fixed `MDBOOK_VERSION`; an existing fixed tag is never replaced.

The documentation workflow builds on pull requests and publishes the mdBook
artifact to [GitHub Pages](https://jeonghanlee.github.io/Dockerfiles/) on
`master` pushes or manual runs.

## Documentation

| Document | Purpose |
|---|---|
| [docs/README.md](docs/README.md) | Documentation index |
| [docs/SETUP.md](docs/SETUP.md) | Debian 13 host and Docker environment setup |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Repository architecture and data flow |
| [docs/MAINTENANCE.md](docs/MAINTENANCE.md) | Image, version, gate, and publication procedures |
| [docs/IMAGE_FOOTPRINT.md](docs/IMAGE_FOOTPRINT.md) | Image size axes, commands, and history |
| [docs/CLOSED_DOORS.md](docs/CLOSED_DOORS.md) | Examined candidates deliberately left unchanged |
| [docs/milestone-69b9303.md](docs/milestone-69b9303.md) | Canonical Work Register |
