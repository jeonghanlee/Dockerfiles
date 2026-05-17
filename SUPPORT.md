# Repository Support Notes

## Scope

This document covers maintenance procedures for this Docker image repository.

**Out of scope:** Docker Hub credential rotation, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Add a New Image

1. Create the Docker Hub repository.
2. Create a new image directory with `Dockerfile` and `env.conf`.
3. Set `TARGET_NAME`, `DOCKER_ID`, `DOCKER_BUILD_OPTS`, and `BUILD_ARGS` in `env.conf`.
4. Add a workflow in `.github/workflows/<image>.yml`.
5. Add the image to `release.bash` only if it participates in release tag updates.
6. Add the image to the table in `README.md`.
7. Run the local dry-run check.

```bash
make dry-run.<image>
```

## Update Release Tags

Set a specific release tag across active release workflows:

```bash
./release.bash v2.5.1
```

Set `latest` without an interactive prompt:

```bash
./release.bash -f
```

Preview tag updates without editing workflow files:

```bash
./release.bash -n v2.5.1
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
