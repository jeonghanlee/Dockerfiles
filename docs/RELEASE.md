# Release an EPICS-env-distribution version

This procedure moves all 18 EPICS images to one EPICS-env-distribution release. The release tags every image with the
distribution version: `make dist-version.<version>` sets both `DIST_VERSION` and `IMAGE_VERSION` in
`configure/VERSIONS`.

Two roles take part:

- The agent runs the read-only `make` targets, edits files when the owner asks, prepares commit messages, and reports
  each result. The agent never commits, pushes, or publishes.
- The owner answers each **Stop** question and runs the commit, the push, and the publication.

Both roles work in one checkout, `<repo_path>`, the absolute path of the agent's checkout: the agent runs every `make`
target there, and every Git command runs there, written as `git -C <repo_path> ...`. The owner runs each Git command
that changes the checkout or the remote, such as commit, push, pull, reset, and revert. The agent runs the commands
that only read or update the remote-tracking refs, such as `status`, `diff`, `log`, `rev-parse`, and `fetch`, and a
command a status target marks `agent` after the owner confirms it. The status targets print each Git command with
the checkout path and mark who runs it.

The agent asks one question at a time and starts the next step only after the owner answers. When a command fails or
prints output that this page does not describe, the agent stops, reports the exact output, and asks the owner what to
do. `make release-status` and `make release-abandon-status` are the exceptions: each exits with a `make` error until
all its stages pass, and a `FAIL` line at the stage reached so far is the expected state, not a failure.

## Scope

This procedure covers one release of the 18 EPICS images: six development images (`<os>-epics`), six `-epics-runner`
images, and six `-epics-slim` images. It covers the distribution check, the component review, the version change, the
commit, the publication, resuming an interrupted release, and abandoning a release.

**Out of scope:** adding an image or an operating-system tree (see "Add an Image" in [MAINTENANCE.md](MAINTENANCE.md)),
the mdBook image (see "Update the mdBook Version" in [MAINTENANCE.md](MAINTENANCE.md)), building the distribution,
which the EPICS-env-distribution repository owns, and a release that raises only `IMAGE_VERSION` with
`make image-version.<v>`. This procedure requires `DIST_VERSION` equal to `IMAGE_VERSION`: `make release-check` and
the `versions` stage of `make release-status` fail for an image-only version.

## Prerequisites

- The tools of [SETUP.md](SETUP.md), plus `curl`, `jq`, `gh`, and `docker buildx`.
- `gh` logged in with read access for the agent, and with write access to `jeonghanlee/Dockerfiles` for the owner.
- The repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`, which `release.yml` uses to push.
- `<repo_path>` on `master`, clean, and matching `origin/master` when a release starts. Before the first run of
  step 1, `git -C <repo_path> status --short` prints nothing, and `git -C <repo_path> rev-parse HEAD` prints the
  same commit as `git -C <repo_path> ls-remote origin refs/heads/master`. Otherwise, the agent stops and asks the
  owner. The owner commits and
  pushes a change that is not part of the release, such as a tooling or Dockerfile change, as its own commit before
  step 1: the release commit of step 5 holds only the `configure/VERSIONS` change of steps 1 to 3, which "Abandon a
  release" relies on. That change is the release change: it stays uncommitted until step 5, also when step 1 runs
  again or a release resumes, and it is never committed before step 5. A later fix commit of step 6 or 7 holds the
  fix and any `configure/VERSIONS` change it needs, and counts as a release commit.
- `.github/workflows/release.yml` on `master`, since `gh workflow run` starts only a workflow on the default branch.
- For "Abandon a release" only, a local `docker login` of the owner with push access to `jeonghanlee/*` on Docker Hub.

`<version>` is the distribution release in the form `X.Y.Z`, for example `1.5.0`.

## Resume an interrupted release

The release keeps no state of its own; Git, GitHub Actions, and Docker Hub hold it. A release that the owner has
abandoned continues under "Abandon a release", not here. To find where a release stands, print its status:

```bash
make release-status VERSION=<version>
```

The target checks six stages in order and stops at the first unfinished one:

| Stage | PASS when |
| --- | --- |
| `versions` | `configure/VERSIONS` has `DIST_VERSION` and `IMAGE_VERSION` equal to `<version>` |
| `git` | The working tree is clean and `HEAD` equals `origin/master` |
| `ci` | Each of the 18 image workflows has a successful `master` run with no change to its path filters since |
| `run` | The newest `release.yml` run has completed, or none exists; its line shows the run ID and commit |
| `hub` | Each of the 18 Docker Hub repositories has the tag `<version>` |
| `latest` | Each `latest` tag has the digest of `<version>` |

The `FAIL` line explains the stage, and the last line, `Next:`, names the next action:

| `Next:` starts with | Continue at |
| --- | --- |
| `make release-check` | Step 1, then every later step in order, including the **Stop** of step 2 |
| `commit and push` | Step 3 again, then step 5 |
| `push HEAD`, `pull`, `fetch`, `restore access` | Run the printed command as marked; then print the status again |
| `stop and ask the owner` | Stop and ask the owner about what the `FAIL` line and the `Next:` line name |
| `wait for the running`, `start each listed`, `check gh auth` | Step 6 |
| `wait for release run`, `cancel release run` | Run the printed command as marked; a cancel continues at step 6 |
| `run the release workflow` | Step 7 |
| `Docker Hub could not be read` | Print the status again once Docker Hub answers; never start step 7 for it |
| `make release-verify` | Verification |

## Procedure

1. To confirm that the distribution release exists for every image, check it:

   ```bash
   make release-check VERSION=<version>
   ```

   The output ends with `Release check: OK (<version>, 6 trees)`. A `FAIL` line names the missing tag or tree; a
   missing EPICS base directory also lists the base directories that the tree holds. When that `found:` list shows
   another EPICS base, such as `found: 7.0.11`, ask the owner whether to set `EPICS_VERSION` in
   `configure/VERSIONS` to it. On yes, edit the line and run step 1 again; the edit is part of the release change that
   step 5 commits. On no, the release stops: no image can be built from that tree. A `NOTE` line names a
   distribution tree that no image uses; it does not block the release, and adding an image for it is out of scope.
   A `FAIL  cannot read <repository URL>` line means that GitHub could not be read; run step 1 again once it answers.

   **Stop.** Ask the owner to confirm `<version>`. On no, the release stops.

2. To review the pinned components, compare them with their upstream tags:

   ```bash
   make release-components
   ```

   Each row shows one `configure/VERSIONS` key with its status:

   - `current`: the pinned version is the highest upstream tag.
   - `newer`: a higher upstream tag exists.
   - `held`: a higher upstream tag exists, and the key is in `HELD_VERSION_KEYS` of `configure/CONFIG_SITE`. A held
     key is raised only for a security fix.
   - `MISSING`: the pinned tag does not exist upstream. The target fails.

   The `DIST_VERSION` row shows `newer` until step 3 sets it.

   **Stop.** For each `newer` or `held` row other than `DIST_VERSION`, ask the owner whether to raise it. For each key
   the owner raises, edit its line in `configure/VERSIONS` to the bare version number, without the `v` that some
   upstream tags carry, for example `S6_VERSION=2.15.1.1`. The three held keys are one set: raise them together, to
   versions whose upstream `INSTALL` files require each other, for example s6 with the skalibs and execline versions
   that its `INSTALL` names.

   To confirm the edits, compare the components again:

   ```bash
   make release-components
   ```

   Each raised key shows `current`, or `newer` or `held` when the owner chose a lower tag; no row shows `MISSING`, and
   the last line is `Components: OK (<n> checked)`. A raise that also needs a Dockerfile change, such as a new
   configure option, is not part of this procedure: the owner commits that change first, as the Prerequisites state.

3. To set the release version, write it and check the repository:

   ```bash
   make dist-version.<version>
   make versions
   make check
   ```

   The first command prints `DIST_VERSION=<version>` and `IMAGE_VERSION=<version>`. `make versions` prints every
   `configure/VERSIONS` key, and `make check` ends without an error.

4. To test an image before the commit, build it and run its gate. The step is optional, except when step 1 or 2
   changed a key other than `DIST_VERSION` and `IMAGE_VERSION`: then build at least one image that uses each changed
   key.

   | Key | Images that use it |
   | --- | --- |
   | `EPICS_VERSION`, `PROCSERV_ENV_VERSION`, `CON_VERSION` | The six development images |
   | The three held keys | `debian12`, `rocky8`, `rocky10`, `ubuntu24`, and their runner and slim images |
   | `RUNNER_VERSION` | The 12 runner and slim images |

   The commands build and gate one image:

   ```bash
   make build.<image_dir>
   make gate.<image_dir>
   ```

   `<image_dir>` is an image directory such as `debian13` or `debian13-epics-slim`. Build a development image before
   its runner or slim image: the local build tags it `latest` and `<version>`, and the runner or slim build uses that
   local tag. The gate ends with the line `-- <n> passed, 0 failed --`; any other count of failed checks stops the
   release at this step, and the agent reports the output.

   **Stop.** Before building, ask the owner which images to build, naming the images the table requires. The agent
   builds only the images the owner names; when no key was changed, the owner can answer none.

5. To publish the change to `master`, the agent first shows the owner what the commit holds:

   ```bash
   git -C <repo_path> status --short
   git -C <repo_path> diff
   ```

   For the release commit, the first command prints only ` M configure/VERSIONS`, and the diff changes only the keys
   of steps 1 to 3. For a fix commit of step 6 or 7, the first command also lists the fixed files, and the owner
   confirms each of them. The agent then prepares the commit message, and the owner commits those files and pushes
   with `git -C <repo_path> push`. `make release-status VERSION=<version>` then shows `versions` and `git` as PASS.

6. To confirm that every image builds and passes its gate on GitHub, wait for the 18 image workflows that the push
   starts, and print the status:

   ```bash
   make release-status VERSION=<version>
   ```

   The `ci` stage shows `PASS  ci         18/18 covered by a successful run`. A runner or slim workflow builds its
   development image in the same job, so the workflows do not need the new tags on Docker Hub. When a workflow fails,
   the agent reports the failing job log, and the owner decides the fix. A failure that needs a repository change is
   fixed by a new commit, which repeats steps 3 and 5. A failure that needs no repository change, such as a network
   error, is fixed by starting the workflow again with the command below. A workflow listed under `no master run` or
   `changed since the last run` has no run that covers `HEAD`; when it stays listed after the other runs finish, the
   owner starts it with the same command:

   ```bash
   gh workflow run <image_dir>.yml -R jeonghanlee/Dockerfiles --ref master
   ```

   A workflow listed under `gh cannot read the runs` means that `gh` failed; the agent checks `gh auth status`.

7. To publish the 18 images from the commit that step 6 covered, print the status right before the start:

   ```bash
   make release-status VERSION=<version>
   ```

   The `versions`, `git`, `ci`, and `run` stages show `PASS`, and the last line starts with
   `Next: run the release workflow`. Any other output means that `master` moved, that CI no longer covers it, or that
   a release run is still going: continue as the `Next:` table names. The agent notes the run ID on the `run` line,
   when the line shows one. When that line shows a completed run with `(failure)` or `(cancelled)`, the agent first
   reports the failing job log of that run, and the owner decides the fix as the end of this step describes, before a
   new start.

   When this start follows a fix to an image that already has `<version>` on Docker Hub, the owner first deletes that
   `<version>` tag on the repository's Docker Hub Tags page, and, for a development image, the tags of its runner and
   slim images too; otherwise the run skips those images. Then the owner starts the release workflow:

   ```bash
   gh workflow run release.yml -R jeonghanlee/Dockerfiles --ref master -f version=<version>
   ```

   The command returns once the run is queued, and the run builds from the `master` commit of that moment. To find
   the new run, print the status again until the `run` line shows a run ID other than the one noted before:

   ```bash
   make release-status VERSION=<version>
   ```

   A `run` line that ends with `on HEAD <commit>` shows that the run builds the commit that step 6 covered; its
   `Next:` line prints the `gh run watch <run_id>` command that follows the run until it ends. A `run` line that ends
   with `not HEAD <commit>` shows that `master` moved before the start; its `Next:` line prints the `gh run cancel`
   command, and the release continues at step 6 after the owner runs it.

   The workflow publishes the six development images first, and the 12 runner and slim images after all six succeed.
   For each image, it skips the build when Docker Hub already has `<version>`; otherwise it builds, runs the gate, and
   pushes `<version>`. It then points `latest` at `<version>` and checks that both tags have one digest.

   When the run fails, the agent reports the failing job log, and the owner decides the fix. A failure that needs no
   change in the repository, such as a network error, is fixed by starting this step again from its beginning; the
   new run continues with the images that do not have `<version>` on Docker Hub. A failure that needs a repository
   change is fixed by a new commit, which repeats steps 3, 5, and 6 before this step starts again.

8. To confirm the publication, print the status:

   ```bash
   make release-status VERSION=<version>
   ```

   All six stages show `PASS`, and the last line is `Next: make release-verify VERSION=<version>`. When another
   person pushed to `master` after the release run started, the `git` and `ci` stages judge that newer commit: a
   `FAIL` there is not a release fix. The agent stops and asks the owner, and shows the `hub` and `latest` stages with
   `make release-status VERSION=<version> ALL=1`.

## Abandon a release

When the owner stops a release for good, the release is taken back to the previous version: `IMAGE_VERSION` on
`origin/master` and the `latest` tag of every image return to the value before the release, and no image keeps the
`<version>` tag, which would make a later `release.yml` run skip that image. The steps of the release no longer apply;
the `Next:` lines of `make release-status` do not apply either.

1. To find the actions that remain, print the abandonment status:

   ```bash
   make release-abandon-status VERSION=<version>
   ```

   The target checks four stages in order and stops at the first unfinished one:

   | Stage | PASS when |
   | --- | --- |
   | `runs` | No `release.yml` run is waiting or running, or `release.yml` is not on the default branch |
   | `local` | `configure/VERSIONS` has no uncommitted change, and `HEAD` equals `origin/master` |
   | `master` | `origin/master` no longer has `IMAGE_VERSION=<version>`; its value is the previous version |
   | `hub` | Every `latest` tag has the digest of the previous version, and no image has the tag `<version>` |

   A `FAIL` line lists the commits or images it concerns, and the `Next:` block below it prints the commands that
   remain, each marked with who runs it. The previous version comes from Git, never from the order of the Docker Hub
   tags: while the release is on `origin/master`, it is the `IMAGE_VERSION` before the release commit, and afterwards
   it is the `IMAGE_VERSION` on `origin/master`.

2. To finish the stage, run the commands of the `Next:` block as each one is marked: the owner runs a command marked
   `owner`, and the agent runs a command marked `agent` only after the owner confirms. The `imagetools create`
   commands need the local `docker login` of the Prerequisites. A tag deletion is done on the repository's Docker Hub
   Tags page that the line names, after `latest` of that repository is back. When a listed commit is not part of the
   release, such as another person's change, the agent stops and asks the owner. At the `master` stage, the owner then
   reverts only the release commits, newest first, with `git -C <repo_path> revert --no-edit <commit>`, where
   `<repo_path>` is the absolute path of the checkout; at the `local` stage, the owner decides what happens to the
   other commit before the target runs again. When a push is rejected because `origin/master` moved, the agent runs
   `git -C <repo_path> fetch` before the target runs again.

3. Repeat steps 1 and 2 until the target prints its last line:

   ```
   Abandon: done (<version> abandoned; latest = <previous_version>)
   ```

   `<previous_version>` is the version that `latest` and `origin/master` returned to. A pushed revert changes
   `configure/VERSIONS`, so it starts the 18 image workflows; they build and gate, and publish nothing.

## Verification

To confirm that each published image came from a release commit on `master`, verify the release:

```bash
make release-verify VERSION=<version>
```

The output has one `PASS` line per image and ends with:

```
Release verify: OK (<version>, 18 images)
```

Each `PASS` line shows that `<version>` and `latest` have one digest, and that the image's
`org.opencontainers.image.revision` label names an `origin/master` commit whose `configure/VERSIONS` matches the image
labels.
