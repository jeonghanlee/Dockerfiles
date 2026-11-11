# Repository Maintenance

## Scope

This document covers image definition changes, fixed version publication, container gates, documentation publication, and repository validation.

**Out of scope:** Docker Hub credential rotation, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Add an Image

1. Create the Docker Hub repository.
2. Create an image directory containing `Dockerfile` and `env.conf`.
3. Set `TARGET_NAME`, `DOCKER_ID`, `DOCKER_BUILD_OPTS`, and `BUILD_ARGS` in `env.conf`.
4. Add a workflow in `.github/workflows/<image>.yml`. For an EPICS image, its push and pull_request path filters list `configure/VERSIONS` and `docker_builder.bash`; a runner or slim workflow also lists its development image directory and passes it as `base_dir`. `make check-versions` checks these rules.
5. Add the directory to `IMAGE_DIRS` in `configure/CONFIG_SITE`.
6. Add an EPICS image to `RELEASE_IMAGE_DIRS`, `RUNNER_IMAGE_DIRS`, or `SLIM_IMAGE_DIRS`, so that `make gate`, `make check-versions`, and `release.yml` cover it.
7. Add the image to `README.md` and `docs/ARCHITECTURE.md`.
8. Run its dry-run and build targets.
9. For an EPICS image, run its container gate after the build.

```bash
make dry-run.<image>
make build.<image>
```

For an EPICS image:

```bash
make gate.<image>
```

## Version Axes

Every version of the 18 EPICS images is one `KEY=value` line of `configure/VERSIONS`; no EPICS image Dockerfile carries a version value. `docker_builder.bash` and the workflows pass the keys a Dockerfile declares as build arguments, and `make check-versions`, part of `make check`, fails when a Dockerfile pins a version or a consumer does not read the file.

| Axis | Set in | Purpose |
|---|---|---|
| `DIST_VERSION` | `configure/VERSIONS`, through `make dist-version.<v>` | Distribution tree consumed |
| `IMAGE_VERSION` | `configure/VERSIONS`, through `make dist-version.<v>` or `make image-version.<v>` | Published image tag |
| `EPICS_VERSION` | `configure/VERSIONS`, edited by hand | EPICS base directory inside the distribution tree |
| Component versions | `configure/VERSIONS`, edited by hand | procServ-env, con, ioc-runner, and the s6 set |
| Generation header | `# version :` in each `Dockerfile`, `gate.bash`, `docker_builder.bash`, `check_versions.bash`, and `release.bash` | File definition revision |

A distribution release sets `IMAGE_VERSION` equal to `DIST_VERSION`: `make dist-version.<v>` writes both. `make image-version.<v>` raises only `IMAGE_VERSION`, to republish images without a distribution change; [RELEASE.md](RELEASE.md) does not cover that case. An image-only `IMAGE_VERSION` must not be a number that a later distribution release uses: `release.yml` skips every image whose version tag already exists on Docker Hub, so that later release would publish nothing new. `IMAGE_VERSION` is published as the Docker Hub tag and, through `BUILD_VERSION`, the `org.label-schema.version` label. `DIST_VERSION` selects the prebuilt EPICS binaries and is recorded in the `epics.distribution-version` label. The generation header marks a change to the file's own definition and is neither an image nor a distribution version.

## Update the EPICS Environment Version

The six development images consume the `EPICS-env-distribution` version in `DIST_VERSION`, and the runner and slim images build on them. Update all of them in one change:

```bash
make dist-version.<v>
make versions
make check
```

`<v>` has the form `X.Y.Z`. [RELEASE.md](RELEASE.md) is the full procedure, from the distribution check to the publication of all 18 images through `.github/workflows/release.yml`. The per-OS workflows only build and gate. `.github/workflows/publish.yml` publishes one image, giving the image directory as the `image_dir` input; it builds, gates, then pushes `latest` and `<IMAGE_VERSION>`, and it replaces an existing `<IMAGE_VERSION>` tag. It adds no `org.opencontainers.image.revision` label, so an image it publishes fails `make release-verify`, and a later `release.yml` run at the same `<IMAGE_VERSION>` skips that image because its tag exists. Publish a runner or slim image with it only after its `<os>-epics` base image is published, since it builds from that base; after republishing a base image, republish its runner and slim images too, because they were built from the replaced base.

`make dist-version.<v>` raises `IMAGE_VERSION` with `DIST_VERSION`, so new distribution content publishes under a new tag. The runner and slim images pin the base `IMAGE_VERSION`, so republishing the same tag would silently change their base.

## Update the mdBook Version

The mdBook workflow treats each version tag as fixed. It rejects publication when that tag already exists. Only an explicit missing-manifest response permits publication; any other registry lookup failure stops the workflow. Runs on the same branch are serialized so two manual publications cannot pass the tag check concurrently.

1. Change `MDBOOK_VERSION` in `mdbook/Dockerfile` to a new version.
2. Build the image and verify the embedded command.

```bash
make build.mdbook
docker run --rm jeonghanlee/mdbook mdbook --version
```

3. Test the documentation against the local image.

```bash
make docs MDBOOK_IMAGE=jeonghanlee/mdbook
```

4. After the change reaches `master`, run `.github/workflows/mdbook.yml` with `workflow_dispatch`.
5. Verify that Docker Hub contains both `latest` and the new fixed version tag.
6. Change `MDBOOK_IMAGE` in `configure/CONFIG_SITE` to the fixed tag.
7. Build the documentation again through the repository default.

```bash
make docs
```

## Run the Container Gate

Build an EPICS image before running its container checks: 12 for a development image, and 13 for a runner or slim image, whose gate runs in supervised mode.

```bash
make build.debian13
make gate.debian13
```

The gate ends with `-- 12 passed, 0 failed --` for `debian13`. `make gate` runs the gate for every EPICS image. The gate uses the default bridge network because its localhost Channel Access and PVAccess checks must stay inside the container.

## Trigger Active Image Rebuilds

Use the tracked trigger when an image rebuild is required without changing an image directory:

```bash
./trigger.bash
```

The next push runs workflows whose path filters include `.trigger/**`.

## Publish Documentation

The repository owner enables GitHub Pages once by selecting `GitHub Actions` under repository Settings, Pages, Build and deployment [1].

The documentation workflow has three entry paths:

| Event | Result |
|---|---|
| Pull request to `master` | Build and link validation only |
| Push to `master` | Build and deploy |
| Manual run on `master` | Build and deploy |

The workflow runs `make docs`, uploads `public/` as the Pages artifact, and deploys through the `github-pages` environment. Add the published URL to `README.md` only after the deploy output and the live HTTP response have been verified.

## Validate Changes

Run the repository checks and documentation build before publishing a change:

```bash
make check
make docs
```

`make check` validates scripts, workflow YAML, ASCII Markdown, local Markdown file targets, diff whitespace, and image build previews. `make docs` renders the complete book with the fixed mdBook image.

## References

[1] GitHub, "Configuring a publishing source for your GitHub Pages site." [Online]. Available: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site [Accessed: Aug. 19, 2026].
