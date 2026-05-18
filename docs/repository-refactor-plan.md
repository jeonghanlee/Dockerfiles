# Repository Refactor Plan

## Scope

This document defines the refactor approach for the Docker image repository. It covers Bash tooling, GitHub Actions workflows, Dockerfile resource usage, documentation boundaries, and verification gates.

**Out of scope:** Rebuilding every image, changing the supported operating-system matrix, publishing Docker Hub tags, or removing historical artifacts without an explicit decision.

## Goals

The refactor should reduce operational risk without changing image behavior unnecessarily. The primary goals are:

- Remove command-injection and quoting risks from local Bash tooling.
- Make local and CI build paths predictable and auditable.
- Reduce Docker build time, network transfer, image size, and cache churn where the package set can remain equivalent.
- Keep OS-specific image behavior visible instead of hidden behind broad rewrites.
- Add verification gates that are cheap enough to run before each commit.

## Current Structure

| Area | Files | Current role |
|---|---|---|
| Local build tooling | `docker_builder.bash`, `release.bash`, `trigger.bash` | Build images locally, update workflow tags, trigger CI rebuilds. |
| EPICS images | `debian*/Dockerfile`, `rocky*/Dockerfile` | Multi-stage EPICS environment images. |
| Utility images | `mdbook/Dockerfile` | Documentation build and rendering image. |
| CI workflows | `.github/workflows/*.yml` | Build and push per-image Docker tags. |
| Configuration | `*/env.conf` | Local build defaults for image names and build options. |
| Project docs | `README.md`, `SUPPORT.md`, `RELEASE.md` | User-facing build and release notes. |

## Initial Findings

### Bash Tooling

`docker_builder.bash` builds a command string and runs it through `eval`. That is the highest-risk local issue because CLI input, environment configuration, and build arguments can affect shell evaluation. It also mishandles multiple build arguments passed as a single string and has an `env.local` discovery path that does not match the file actually sourced.

`release.bash` updates workflow tags in place and creates `.bak` files. It lacks a forced non-interactive mode, has no validation that each target workflow exists and was changed, and reports success before checking the resulting diff.

`trigger.bash` is simple, but it relies on `.trigger/random` as a tracked mutable file. That is acceptable only if the repository intentionally uses it as a CI trigger surface.

### Dockerfiles

The EPICS Dockerfiles repeat the same dependency installation, git clone, package automation, and runtime cleanup patterns across Debian and Rocky variants. Several paths can reduce disk and network use:

- Use shallow clones consistently where build semantics allow it.
- Use `--no-install-recommends` on Debian runtime packages where package behavior is unchanged.
- Use `pip --no-cache-dir` for runtime Python packages.
- Clean package metadata in the same layer as installation.
- Keep builder-only packages out of runtime stages.
- Normalize `SHELL` and default command behavior if `ENTRYPOINT [ "" ]` is not intentional.

Any package removal or runtime command change must be handled as a decision gate because it can change CI runner behavior.

### CI Workflows

The workflow files are mostly copies with small per-image differences. They all build from repository root context, which sends more data to BuildKit than each image needs. Pull-request builds still configure Docker Hub login even though pushing is disabled.

The workflows should be normalized so that each workflow:

- Uses image-directory context when the Dockerfile does not depend on repository-root files.
- Skips Docker Hub login on pull requests.
- Keeps push behavior disabled for pull requests.
- Uses consistent action versions unless a specific workflow needs an exception.
- Uses path filters for both push and pull-request events where practical.

### Documentation

`README.md` and `SUPPORT.md` describe operation, but they mix release procedure, examples, and historical notes. The refactor should split structural guidance from current status:

- `README.md`: short entry point and supported image list.
- `docs/repository-refactor-plan.md`: this plan and acceptance model.
- Optional `docs/repository-status.md`: matrix of applied and verified refactor stages if the work spans multiple commits.

## Refactor Phases

### Phase 0: Baseline Protection

Capture the current branch, working tree state, and static checks before changes. No behavior changes happen in this phase.

Acceptance gates:

```bash
git status --short --branch
bash -n docker_builder.bash release.bash trigger.bash
shellcheck -S warning docker_builder.bash release.bash trigger.bash
```

### Phase 1: Bash Tooling Hardening

Refactor local scripts first because they control local builds and release edits.

Planned changes:

- Add `set -euo pipefail` where compatible.
- Replace `echo` with `printf`.
- Replace command strings plus `eval` with arrays.
- Validate required commands before use.
- Validate target directories and required files before sourcing or parsing.
- Replace broad source behavior with a whitelisted key-value loader where practical.
- Add `--dry-run` and `--force` paths for operations that otherwise prompt.
- Make dry-run output match real-run side effects.

Acceptance gates:

```bash
bash -n docker_builder.bash release.bash trigger.bash
shellcheck -S warning docker_builder.bash release.bash trigger.bash
bash docker_builder.bash -d -t debian13
```

Decision gates:

- Whether local `env.local` remains executable Bash syntax or becomes parsed key-value data.
- Whether `DOCKER_BUILD_OPTS=--network=host` remains the default for every image.
- Whether `.trigger/random` remains tracked or becomes generated-only state.

### Phase 2: CI Workflow Normalization

Normalize workflow structure after local tooling is safe. Keep each workflow file separate unless the repository intentionally moves to a reusable workflow.

Planned changes:

- Skip Docker Hub login for pull-request events.
- Use per-image build context where possible.
- Normalize spacing, action versions, and tag expressions.
- Keep `push: ${{ github.event_name != 'pull_request' }}` behavior.
- Add workflow path filters for pull requests if they do not block expected validation.

Acceptance gates:

```bash
git diff --check
```

Optional gates when tools are available:

```bash
actionlint
yamllint .github/workflows
```

Decision gates:

- Whether to keep one workflow per image or introduce a reusable workflow.
- Whether pull requests should build only changed image families or always build all active images.

### Phase 3: Dockerfile Resource Pass

Optimize Dockerfiles in small OS-family groups. Debian, Rocky, and mdbook should be handled as separate passes because package managers and default dependency policies differ.

Planned Debian changes:

- Replace `apt update` with `apt-get update` for scripting consistency.
- Add `--no-install-recommends` where package behavior is known to stay equivalent.
- Keep `ca-certificates` explicit in stages that use HTTPS so TLS trust does not depend on recommended packages.
- Keep package metadata cleanup in the same `RUN` layer as package installation.
- Use `pip3 install --no-cache-dir` for Python packages.
- Apply shallow clones where full history is not required.

Planned Rocky changes:

- Evaluate `dnf --setopt=install_weak_deps=False install` per runtime package group.
- Use `pip3 install --no-cache-dir` for Python packages.
- Keep `dnf clean all` and cache cleanup in the same layer.
- Keep locale setup explicit for build stages.

Planned utility image changes:

- Keep `mdbook` version pinned.
- Install `mdbook` with Cargo lockfile resolution so dependency updates do not raise the required Rust version unexpectedly.
- Build `mdbook` in a Rust builder stage and copy only the binary into the runtime image.
- Review whether `ENTRYPOINT [ "" ]` should be replaced by `CMD [ "/bin/bash" ]` or omitted.

Acceptance gates:

```bash
git diff --check
```

Optional gates when Docker is available:

```bash
docker build --file debian12/Dockerfile --tag local/debian12-epics:test debian12
docker build --file debian13/Dockerfile --tag local/debian13-epics:test debian13
docker build --file mdbook/Dockerfile --tag local/mdbook:test mdbook
```

Decision gates:

- Any package removal from runtime images.
- Any change to Java major version.
- Any change to default shell, `ENTRYPOINT`, or `CMD`.
- Any change from repository-root build context where a Dockerfile still depends on files outside its directory.

### Phase 4: Documentation and Status

Update user-facing docs after the implementation shape is clear.

Planned changes:

- Keep `README.md` as the entry point.
- Move detailed release and local build guidance into a dedicated document if it grows.
- Add a status matrix only if the refactor spans multiple commits or not all image families are verified in one pass.

Acceptance gates:

```bash
LC_ALL=C grep -rnP '[^\x00-\x7F]' --include='*.md' .
git diff --check
```

Non-ASCII findings are acceptable only when the glyph has technical meaning and is intentionally retained.

## Verification Matrix

| Surface | Gate | Required before merge |
|---|---|---|
| Bash syntax | `bash -n docker_builder.bash release.bash trigger.bash` | Yes |
| Bash static safety | `shellcheck -S warning docker_builder.bash release.bash trigger.bash` | Yes |
| Local builder dry-run | `bash docker_builder.bash -d -t debian13` | Yes |
| Git whitespace | `git diff --check` | Yes |
| Workflow syntax | `actionlint` | When available |
| Dockerfile build | Per-image `docker build` | At least changed image family |
| Image size | `docker image inspect` or CI artifact comparison | When Docker builds run |
| Runtime smoke test | Start shell or expected command in changed image | When Docker builds run |

## Current Status

| Surface | Status | Verification |
|---|---|---|
| Refactor plan | Applied | `git diff --check` |
| Bash helper syntax | Applied | `bash -n docker_builder.bash release.bash trigger.bash` |
| Bash helper static safety | Applied | `shellcheck -S warning docker_builder.bash release.bash trigger.bash` |
| Local build dry-run | Applied | `./docker_builder.bash -d -t <image>` for each image directory |
| Release dry-run | Applied | `./release.bash -n -f` and `./release.bash -n v2.5.1` |
| Workflow YAML parse | Applied | `ruby -e 'require "yaml"; ARGV.each { |p| YAML.load_file(p) }' .github/workflows/*.yml` |
| Workflow resource use | Applied | Per-image build context and pull-request login guard in each workflow |
| Dockerfile cache cleanup | Applied | Static review and local builder dry-run |
| Full image builds | Not run | Requires network access, Docker daemon access, and build time per image |
| Docker Hub publishing | Not run | Push operations are intentionally outside local validation |

The refactor keeps these behaviors unchanged:

- One workflow file per image.
- Active image directories are limited to the maintained EPICS and mdbook images.
- `DOCKER_BUILD_OPTS=--network=host` remains the local default.
- `ENTRYPOINT [ "" ]` remains unchanged in existing Dockerfiles.
- Ignored `.bak` and `.un~` files are not bulk-deleted by this refactor.

## Safety Rules for Implementation

The refactor should follow these rules:

- Do not remove ignored backup files unless cleanup is explicitly approved.
- Retired-image backup files may be removed with the retired image when the cleanup scope explicitly includes that image.
- Do not collapse all Dockerfiles into a generator until manual Dockerfile parity is established.
- Do not update third-party action major versions as part of formatting-only workflow cleanup.
- Do not change image tags, Docker Hub repositories, or supported OS names as part of tooling cleanup.
- Do not describe a stage as verified unless the exact command or CI result is recorded.
- Stop for a decision before changing package contents, runtime defaults, tracked trigger files, or workflow topology.

## Proposed Commit Boundaries

| Commit | Content | Rationale |
|---|---|---|
| 1 | Add refactor plan | Establish scope and gates before behavior changes. |
| 2 | Harden Bash tooling | Remove highest-risk local execution issues first. |
| 3 | Normalize workflow behavior | Reduce CI waste and keep push semantics clear. |
| 4 | Optimize one OS family | Prove Dockerfile pattern on a bounded surface. |
| 5 | Extend Dockerfile pattern | Apply only after the first family passes verification. |
| 6 | Refresh README and status | Document the final supported shape. |

## Open Decisions

These decisions should be made before the related phase starts:

1. Should `env.conf` and `env.local` remain shell files or become parsed key-value files?
2. Should local builds keep `--network=host` as the default?
3. Should ignored `.bak` and `.un~` files be deleted from the working tree?
4. Should GitHub Actions stay as one workflow per image?
5. Should additional retired image directories remain archived outside this repository?
