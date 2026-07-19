# Repository Support Notes

## Scope

This document covers maintenance procedures for this Docker image repository.

**Out of scope:** Docker Hub credential rotation, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Add a New Image

1. Create the Docker Hub repository.
2. Create a new image directory with `Dockerfile` and `env.conf`.
3. Set `TARGET_NAME`, `DOCKER_ID`, `DOCKER_BUILD_OPTS`, and `BUILD_ARGS` in `env.conf`.
4. Add a workflow in `.github/workflows/<image>.yml`.
5. Add the image to `RELEASE_IMAGE_DIRS` in `configure/CONFIG_SITE` if it is an EPICS image (so `make gate` and `make dist-version` cover it).
6. Add the image to the table in `README.md`.
7. Run the local dry-run check.

```bash
make dry-run.<image>
```

## Update the EPICS Environment Version

An image's version is the `EPICS-env-distribution` version pinned in its
`DIST_VERSION` build argument. CI reads that argument and publishes the
`latest` and `<version>` tags from it. A distribution bump is a coordinated
change across all EPICS images:

```bash
make dist-version.1.2.2
```

Review the resulting Dockerfile changes, then commit. Show the current
versions at any time:

```bash
make versions
```

## Trigger Active Image Rebuilds

Use the trigger helper when a rebuild is required without changing an image directory.

```bash
./trigger.bash
```

The workflows that include `.trigger/**` in their path filters will run on the next push.

## Validation

Run these checks before committing script, workflow, or documentation changes:

```bash
make check
```
