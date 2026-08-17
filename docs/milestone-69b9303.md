# Work Register

Release line: master
Milestone index: 69b9303
Canonical path: `docs/milestone-69b9303.md`
Canonical branch or ref: master
Git upstream: origin/master
Remote tracker: jeonghanlee/Dockerfiles, GitHub milestone 2.0.0 ("Lean images, everlasting EPICS")

Next session entry point: M2, modernizing the mdbook image, is In progress. The
image is rebuilt at mdbook 0.5.4 on the trixie base and renders a real book
locally; the remaining step is the owner-run workflow_dispatch publish, after
which the consumer doc repos are verified against the published image - EPICS-env
first, then epics-trainings. The container runtime (M1) is Blocked on the
upstream gate G1; the consumer cutover is tracked as gate G2. The 1.2.2 images
are built, published, and consumer-verified; that work is complete and reachable
in Git at commit 69b9303.

This register is the status source of truth for the remaining master work after
the 1.2.2 release. It replaces `docs/milestone-5c186b4.md`, whose completed rows
and decision records stay reachable at commit 69b9303.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime | M1 | Container runtime: systemd-less ioc-runner on a runtime-only slim image | Carry-forward | Blocked | No | G1 | ioc-runner starts and stops an IOC in a systemd-less container, and a toolchain-free runtime image builds and runs it; [detail](#m1---container-runtime) |
| Images | M2 | Modernize the mdbook image | Milestone | In progress | No | | Image builds with the latest pinned mdbook and renders a site through the GitLab Pages flow; [detail](#m2---modernize-the-mdbook-image) |
| Gates | G1 | epics-ioc-runner container execution mode | External gate | Open | No | | Upstream issue jeonghanlee/epics-ioc-runner#127 resolved; [detail](#g1---epics-ioc-runner-container-mode) |
| Gates | G2 | GitLab consumer cutover | External gate | Open | No | | Consumer rollout of the published images, executed in `alsu/ci`, with no work row here; [detail](#g2---gitlab-consumer-cutover) |

Tally: 2 milestone rows - Complete 0, In progress 1, Blocked 1, Not started 0, Ready 0.
External gates: 2 open (G1, G2). Backlog is reported separately below and
excluded from this tally.

### Milestone Details

#### M1 - Container runtime

Origin: 69b9303 / M1
Identity History: none
GitHub Issue: #28, https://github.com/jeonghanlee/Dockerfiles/issues/28
Status: Blocked

##### Summary

One runtime story in one row. The images ship procServ and con for direct IOC
execution today; ioc-runner stays excluded until it gains a systemd-less
container execution mode, tracked upstream as G1. This milestone joins the two
halves of that story: reintroducing ioc-runner with systemd-less container
start and stop, and a runtime-only slim image (no compiler, no `-devel`
packages) for pure IOC execution under its own tag - the toolchain-free
counterpart to the dev-carrying images already shipped at 1.2.2.

##### Scope

Reintroduce ioc-runner into the runtime image and verify start and stop inside a
systemd-less container across the images. Define and build the runtime-only slim
image with the minimal NEEDED set and its own tag, running IOCs through the
systemd-less ioc-runner.

Out of scope: the upstream ioc-runner change itself (G1); the existing
dev-carrying images.

##### Completion Criteria

- ioc-runner starts and stops an IOC inside a systemd-less container.
- A runtime-only slim image builds with the minimal set, carries its own tag,
  and runs an IOC through ioc-runner.

##### Dependencies And Decisions

- G1 must be Complete before work resumes; resume as Not started when G1 is
  Complete.
- Direct procServ and con execution covers container IOC use meanwhile, so the
  images are usable without ioc-runner until then.
- The slim image is the second half of the package-footprint split; the first
  half - pruning pure surplus while keeping the runner toolchain - already
  shipped in the 1.2.2 images.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope once the upstream container execution mode (G1) exists.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container runtime | Start and stop an IOC through ioc-runner in a running container | Runtime image | Start and stop both succeed without systemd |
| T2 | Image build | Build the runtime-only slim image and run an IOC through ioc-runner | Slim runtime image | Image builds with the minimal set and runs the IOC |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Runtime image | Pending | none |
| T2 | Not run | Slim runtime image | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add the IOC runtime layer: procServ, con, IOC generator tools
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-17, register reset
Scope note: issue #28 spans procServ, con, ioc-runner, and the tools IOC
generator. procServ and con shipped at 1.2.2; the tools generator was retired
2026-08-17 (it stays a standalone tool). M1 covers only the remaining half - the
systemd-less ioc-runner runtime. A retirement comment records this on #28.

#### M2 - Modernize the mdbook image

Origin: 69b9303 / M2
Identity History: none
GitHub Issue: #32, https://github.com/jeonghanlee/Dockerfiles/issues/32
Status: In progress

##### Summary

The mdbook image is the one remaining non-EPICS image in the repository. It was
left untouched by the 2026 rework and is scheduled independently of it. Its
workflow differs from the three EPICS images - it uses its own build variables
rather than the reusable `image.yml`. Modernized to mdbook 0.5.4 on the trixie
base, with publishing brought under the same owner-gated `workflow_dispatch`
model as the three EPICS images. The PDF tool set is kept unchanged.

##### Scope

Rebuild the mdbook image on the trixie base with a pinned mdbook 0.5.4 release,
and gate its publish on `workflow_dispatch` on master.

Out of scope: the three EPICS images; the consumer doc repositories, whose
book.toml migration to mdbook 0.5 is handled per repository.

##### Completion Criteria

- The image builds with the latest pinned mdbook and renders a site through the
  GitLab Pages template flow.
- The image is published to Docker Hub via the gated `workflow_dispatch`.

##### Dependencies And Decisions

- None. The image work has no dependencies.
- The 0.4 to 0.5 change is breaking for consumer book.toml (Font Awesome 6
  validates icon prefixes; an old `fa-<brand>` icon such as `fa-gitlab` is
  rejected, and must become `fab-<brand>`). Consumer repositories fix this per
  repository; repositories with no `git-repository-icon` line are unaffected.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-17, in session
Implementation Authorization: owner, 2026-08-17, in session
Superseded Plan Artifacts: none

1. Pin mdbook 0.5.4 and rebuild on the trixie base and builder, keeping the PDF
   tool set.
2. Gate the publish on `workflow_dispatch` on master, matching the EPICS images.
3. Verify the image renders a real book; publish; then verify the consumer doc
   repos against the published image - EPICS-env first, then epics-trainings.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Build and render | Build the image, then render a site through the GitLab Pages template flow | mdbook image | Build succeeds and the site renders |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-17 | Local, mdbook:0.5.4 image | Pass | Image built (mdbook v0.5.4, Debian 13 trixie, PDF tools present); rendered the epics-trainings book (33 pages) through `mdbook build` after the `fab-gitlab` icon fix |

##### Closure Evidence

- Remaining for Complete: the owner-run `workflow_dispatch` publish to Docker
  Hub, then consumer-repo verification (EPICS-env, then epics-trainings).

##### GitHub Projection

Title: Modernize the mdbook image
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-17, register reset

#### G1 - epics-ioc-runner container mode

Origin: 69b9303 / G1
GitHub Issue: jeonghanlee/epics-ioc-runner#127
Status: Open

##### Summary

ioc-runner needs a systemd-less container execution mode before M1 can proceed.
The work is owned by the `epics-ioc-runner` repository and sits in its backlog.

##### Completion Criteria

- epics-ioc-runner#127 is resolved and a container execution mode is released.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | jeonghanlee/epics-ioc-runner#127, backlog |

##### Closure Evidence

- none

#### G2 - GitLab consumer cutover

Origin: 69b9303 / G2
GitHub Issue: none
Status: Open

##### Summary

The GitLab consumers must move to the published images in one coordinated change
with no transition stub: the `alsu/ci` template change and the runner-image
rollout land together. This gate governs when the images reach their consumers;
the executing work lives in the `alsu/ci` repository, not here. The consumer
build path was verified this cycle - 37 of 38 alliocs IOCs build against the
published debian13-epics:1.2.2, the one failure being a consumer feed-core
dependency unrelated to the image.

##### Completion Criteria

- The `alsu/ci` template change is committed and the runner images are rolled
  out in the same cutover.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | Consumer cutover executed in `alsu/ci` |

##### Closure Evidence

- none

## Backlog

Backlog rows are unassigned, use the same schema, and are excluded from the
release tally.

### Work

The backlog is empty. Two rows carried by the prior generation were retired by
owner decision on 2026-08-17:

- Image vulnerability scanning (report-only): retired because the findings are
  dominated by base-OS packages this repository cannot act on.
- Bundling the `tools` IOC generator into the images: retired; the generator
  stays a standalone tool rather than shipping inside the images.

Their full prior records remain in Git at commit 69b9303, in
`docs/milestone-5c186b4.md` (rows M5 and M7).

## History

| Date | Prior-state commit |
| --- | --- |
| 2026-08-17 | 69b93034c6fee25158073d7b217d7429f7f8dda7 |
