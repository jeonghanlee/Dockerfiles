# Repository Maintenance

## Scope

This document covers image definition changes, fixed version publication, container gates, documentation publication, and repository validation.

**Out of scope:** Docker Hub credential rotation, GitHub organization policy, EPICS source maintenance, and downstream GitLab runner deployment.

## Add an Image

1. Create the Docker Hub repository.
2. Create an image directory containing `Dockerfile` and `env.conf`.
3. Set `TARGET_NAME`, `DOCKER_ID`, `DOCKER_BUILD_OPTS`, and `BUILD_ARGS` in `env.conf`.
4. Add a workflow in `.github/workflows/<image>.yml`.
5. Add the directory to `IMAGE_DIRS` in `configure/CONFIG_SITE`.
6. Add an EPICS image to `RELEASE_IMAGE_DIRS` so `make gate` and `make dist-version` cover it.
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

## Update the EPICS Environment Version

The three EPICS images pin the `EPICS-env-distribution` version in `DIST_VERSION`. Update them as one coordinated change:

```bash
make dist-version.1.2.2
make versions
make check
```

Review all three Dockerfile changes. The EPICS image workflows publish `latest` and `<DIST_VERSION>` only from a manual `workflow_dispatch` on `master`, after their container gates pass.

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

Build an EPICS image before running its 11 container checks:

```bash
make build.debian13
make gate.debian13
```

`make gate` runs the gate for every EPICS image. The gate uses the default bridge network because its localhost Channel Access and PVAccess checks must stay inside the container.

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
