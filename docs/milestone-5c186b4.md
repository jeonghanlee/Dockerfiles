# Work Register

Release line: master
Milestone index: 5c186b4
Canonical path: `docs/milestone-5c186b4.md`
Canonical branch or ref: master
Git upstream: origin/master
Remote tracker: jeonghanlee/Dockerfiles, GitHub milestone 2.0.0 ("Lean images, everlasting EPICS")

Next session entry point: nothing here is startable. Every remaining row waits
on an external gate - G1 for the ioc-runner container mode, G2 for Docker Hub
publish authorization, G3 for the GitLab consumer cutover. When one resolves,
open its M row and restore the executable status recorded there. Until then
the register needs no attention.

This register is the status source of truth for the remaining 2026 image rework.
It replaces `docs/milestone.md`, whose completed content stays reachable at
commit 5c186b4.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Images | M1 | Recapture the three image sizes at DIST_VERSION 1.2.2 on this host | Milestone | Complete | No | D5, D6, D7, D12 | Three images build locally at 1.2.2 and their sizes are recorded; [detail](#m1---recapture-image-sizes-at-122) |
| Runtime | M2 | Reintroduce ioc-runner (container execution mode) | Carry-forward | Blocked | No | G1, D3 | ioc-runner start and stop work in a systemd-less container; [detail](#m2---reintroduce-ioc-runner) |
| Publish | M3 | Publish the images to Docker Hub | Carry-forward | Blocked | No | G2, D1 | Tags visible on Docker Hub per the D1 scheme; [detail](#m3---publish-to-docker-hub) |
| Gates | G1 | epics-ioc-runner container execution mode | External gate | Open | No | | Upstream issue jeonghanlee/epics-ioc-runner#127 resolved; [detail](#g1---epics-ioc-runner-container-mode) |
| Gates | G2 | Docker Hub publish authorization and execution | External gate | Open | No | | Owner authorizes and runs the gated publish workflow; [detail](#g2---docker-hub-publish-authorization) |
| Gates | G3 | GitLab consumer cutover | External gate | Open | No | D2 | Blocks the consumer rollout of the published images, which is executed in `alsu/ci` and has no work row in this register; complete when the template change and the runner-image rollout land together; [detail](#g3---gitlab-consumer-cutover) |

Tally: 3 milestone rows - Complete 1, In progress 0, Blocked 2, Ready 0.
External gates: 3 open (G1, G2, G3). Backlog is reported separately below and
excluded from this tally.

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | Image names stay `<os>-epics`; version tags follow the `EPICS-env-distribution` release (e.g. `debian13-epics:1.2.2`); `latest` tracks the newest; the EPICS base version is recorded in image labels | Owner, 2026-07-18 |
| D2 | The GitLab consumer cutover is coordinated with no transition stub: the `alsu/ci` template change and the runner-image rollout land together; `rocky10-epics.yml` (builder-only) is authored in the ci repository | Owner, 2026-07-18 |
| D3 | ioc-runner stays out of the images until its container execution mode exists; direct procServ execution covers container IOC use meanwhile | Owner, 2026-07-18 |
| D4 | The consumer-compile deep gate is the alliocs harness, owned and tracked in the alliocs register (its M4.5), not in this repository | Owner, 2026-07-18 |
| D5 | M1 requires only the container gate (done at 1.2.2) plus the image-size recapture; the deep gate is not re-run here per D4 | Owner, 2026-08-14 |
| D6 | `DIST_VERSION` is 1.2.2 across the three EPICS Dockerfiles; upstream removed 1.2.1, so every measurement taken against 1.2.1 is superseded | Owner, 2026-08-13 |
| D7 | Version management is the Dockerfile `DIST_VERSION` ARG as the single source, `make dist-version.<v>` to bump all EPICS images, `make versions` to show them; `release.bash` is retired | Owner, 2026-07-19 |
| D8 | Image vulnerability scanning is backlogged; base-OS findings are not actionable in this repository | Owner, 2026-07-18 |
| D9 | The package footprint splits in two designs: prune pure surplus while keeping the runner dev toolchain (done at 1.2.1, carried by the current Dockerfiles), and a separate runtime-only slim image without a toolchain (backlog) | Owner, 2026-07-18 |
| D10 | The `tools` IOC generator is deferred out of the runtime layer and held in the backlog | Owner, 2026-07-19 |
| D11 | `con` and `procServ-env` stay unpinned at floating default-branch HEAD, with the commit recorded in the bake manifest, because `procServ-env` has no released version number yet | Owner, 2026-08-14 |
| D12 | The 1.2.2 image-size recapture runs on this host; Docker Hub registry access from this host is confirmed working | Owner, 2026-08-14 |

The decisions below explain the shape of the shipped images. They were carried
in source comments until the register reset showed that comment-embedded IDs go
stale; the code now reads on its own and this table is their only record.

| ID | Decision | Source |
| --- | --- | --- |
| D13 | The images consume prebuilt `EPICS-env-distribution` binaries; nothing EPICS is compiled during an image build. The consumer build toolchain stays resident because runner jobs compile IOCs inside the running container. Vendor libraries arrive inside the distribution `vendor/` tree, so there are no separate build layers | Owner, 2026-07-18 |
| D14 | `setEnv` is removed and the environment is baked with Dockerfile `ENV`: `EPICS_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH`, `PATH` (pmac, then pvxs, then base bins, prepended in that precedence order), and `LD_LIBRARY_PATH` (base lib only, modules resolving through their RUNPATH) | Owner, 2026-07-18 |
| D15 | The in-image install root is `/opt/epics/<dist-version>/<os-dir>/<epics-version>`, preserving the distribution tree shape with the version visible in the path | Owner, 2026-07-18 |
| D16 | Analyzer tools are excluded from the images; the GitLab tester jobs that used them were removed on the consumer side | Owner, 2026-07-18 |
| D17 | Pure surplus packages are pruned while the runner dev toolchain stays: X11/Motif, netcdf/tiff/png/bz2, boost, hidapi, the PCRE1 family, libcurl, and the legacy libusb 0.1 API were removed after a dependency review found no linkage, no module-header reference, and no consumer IOC build using them | Owner, 2026-07-18 |
| D18 | The rocky10 base is pinned to `rockylinux:10.2` because it matches the distribution build OS; new minors are followed promptly with a distribution rebuild, since the rocky10 line exists to catch next-stable problems early | Owner, 2026-07-18 |
| D19 | `procServ` and `con` are built from source in the final stage with the resident toolchain, using recipes that mirror the ansible-provision roles, with the transient autotools set installed and removed in the same layer | Owner, 2026-07-19 |

### Milestone Details

#### M1 - Recapture image sizes at 1.2.2

Origin: 5c186b4 / M1
Identity History: none
GitHub Issue: #27, https://github.com/jeonghanlee/Dockerfiles/issues/27
Status: Complete

##### Summary

The 2026 rework measured every image property against `EPICS-env-distribution`
1.2.1, which upstream has since removed. The Dockerfiles now pin 1.2.2 (D6) and
the container gate was re-run green at 1.2.2 in the PR #34 CI run. The one
measurement not yet retaken at 1.2.2 was the image size of the three EPICS
images. Per D12 that recapture ran on this host.

##### Scope

Build debian13, rocky8, and rocky10 at `DIST_VERSION=1.2.2` on this host and
record the resulting image sizes.

Out of scope: the consumer-compile deep gate (D4, D5); the container gate,
which is already green at 1.2.2 in CI; Docker Hub publish (M3); the mdbook
image, which carries no EPICS distribution.

##### Completion Criteria

- All three EPICS images build locally at 1.2.2.
- The size of each built image is recorded in Verification Results.

##### Dependencies And Decisions

- D5 scopes M1 to the container gate plus the size recapture.
- D6 fixes the measured version at 1.2.2.
- D7 defines `DIST_VERSION` as the version source.
- D12 places the recapture on this host.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-14, in session
Implementation Authorization: owner, 2026-08-14, in session
Superseded Plan Artifacts: none

1. Confirm `make versions` reports 1.2.2 for all three EPICS images.
2. Run `make build.debian13 build.rocky8 build.rocky10` on this host. Plain
   `make build` also builds mdbook, which is out of scope here.
3. Measure every size axis with the commands defined in
   `docs/IMAGE_FOOTPRINT.md`. A single measurement is not enough: one image
   reports four different sizes that differ by up to a factor of five, and the
   axis a figure sits on decides whether it can be compared to anything.
4. Record the measurements in `docs/IMAGE_FOOTPRINT.md` and close M1.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Build and measurement | `make build.debian13 build.rocky8 build.rocky10`, then the four axis commands defined in `docs/IMAGE_FOOTPRINT.md` | Local Docker 29.7.1 | Three images built at 1.2.2, each measured on all four axes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-14 | Local Docker 29.7.1 | Pass | Three images built at 1.2.2 and measured on all four axes; figures recorded in `docs/IMAGE_FOOTPRINT.md` |

`docs/IMAGE_FOOTPRINT.md` is the record for every size figure. It is not
copied here, so there is one place to read and one place to update. It sits
outside this register so the history survives future resets.

##### Closure Evidence

- Images built at 1.2.2 on this host 2026-08-14 and measured on all four axes;
  figures and measuring commands recorded in `docs/IMAGE_FOOTPRINT.md`.
- The same commands were applied to the previous-generation images pulled from
  Docker Hub, giving the first cross-generation comparison on matching axes.
- Distribution 1.2.1 was not re-measured, and by owner decision will not be.
  The axis of its figures stays unknown; the rows are kept as a known gap
  rather than closed silently.

##### GitHub Projection

Title: Rebuild images from the prebuilt EPICS-env-distribution
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: closed
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-14, after closing #27 on the completed recapture

#### M2 - Reintroduce ioc-runner

Origin: 5c186b4 / M2
Identity History: none
GitHub Issue: #28, https://github.com/jeonghanlee/Dockerfiles/issues/28
Status: Blocked

##### Summary

The images ship procServ and con for direct IOC execution. ioc-runner is
excluded until it gains a container execution mode (D3), which is tracked
upstream as G1.

##### Scope

Reintroduce ioc-runner into the three EPICS images and verify start and stop
inside a systemd-less container.

Out of scope: the upstream ioc-runner change itself, which is G1.

##### Completion Criteria

- ioc-runner starts and stops an IOC inside a systemd-less container in all
  three images.

##### Dependencies And Decisions

- G1 must be Complete before work resumes.
- D3 records the exclusion and its rationale.
- Resume as Not started when G1 is Complete.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope once the upstream container mode exists.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container runtime | Start and stop an IOC through ioc-runner in a running container | All three EPICS images | Start and stop both succeed without systemd |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | All three EPICS images | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add the IOC runtime layer: procServ, con, IOC generator tools
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-14, register reset

#### M3 - Publish to Docker Hub

Origin: 5c186b4 / M3
Identity History: none
GitHub Issue: #30, https://github.com/jeonghanlee/Dockerfiles/issues/30
Status: Blocked

##### Summary

The reusable `image.yml` workflow builds, loads, gates, and only then publishes,
and it publishes only on a manual `workflow_dispatch` on master. The publish
itself awaits owner authorization and execution, tracked as G2.

##### Scope

Publish the three EPICS images to Docker Hub under the D1 tag scheme.

Out of scope: workflow changes, which are complete and carried by the current
`.github/workflows` tree.

##### Completion Criteria

- `latest` and the `DIST_VERSION` tag are visible on Docker Hub for all three
  EPICS images.

##### Dependencies And Decisions

- G2 must be Complete before work resumes.
- D1 defines the tag scheme.
- Resume as Not started when G2 is Complete.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Owner runs the `workflow_dispatch` publish on master after G2.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Registry | Inspect the published tags on Docker Hub | Docker Hub | `latest` and the version tag present for all three images |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Docker Hub | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Modernize the CI matrix and Docker Hub tag scheme
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-14, register reset

#### G1 - epics-ioc-runner container mode

Origin: 5c186b4 / G1
GitHub Issue: jeonghanlee/epics-ioc-runner#127
Status: Open

##### Summary

ioc-runner needs a container execution mode before M2 can proceed. The work is
owned by the `epics-ioc-runner` repository and sits in its backlog, filed
2026-07-18.

##### Completion Criteria

- epics-ioc-runner#127 is resolved and a container execution mode is released.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | jeonghanlee/epics-ioc-runner#127, backlog |

##### Closure Evidence

- none

#### G2 - Docker Hub publish authorization

Origin: 5c186b4 / G2
GitHub Issue: none
Status: Open

##### Summary

Publishing to Docker Hub requires the owner to authorize and run the gated
publish workflow. No agent runs it.

##### Completion Criteria

- The owner authorizes the publish and runs the `workflow_dispatch` on master.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | Owner-run publish |

##### Closure Evidence

- none

#### G3 - GitLab consumer cutover

Origin: 5c186b4 / G3
GitHub Issue: none
Status: Open

##### Summary

The GitLab consumers must move to the new images in one coordinated change with
no transition stub (D2). The `alsu/ci` template change and the runner-image
rollout land together. This gate is tracked here because it governs when the
images reach their consumers; the executing work lives in the `alsu/ci`
repository, not in this one.

##### Completion Criteria

- The `alsu/ci` template change is committed and the runner images are rolled
  out in the same cutover.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | `rocky10-epics.yml` builder-only template authored in the ci repository, uncommitted as of 2026-07-18 |

##### Closure Evidence

- none

## Backlog

Backlog rows are unassigned, use the same schema, and are excluded from the
release tally.

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Images | M4 | Modernize the mdbook image | Milestone | Open | No | | Assignment condition: the owner schedules the mdbook line; [detail](#m4---modernize-the-mdbook-image) |
| Images | M5 | Image vulnerability scanning, report only | Milestone | Deferred | No | D8 | Assignment condition: a new owner decision returns it to current execution; [detail](#m5---image-vulnerability-scanning) |
| Images | M6 | Runtime-only slim image variant | Milestone | Deferred | No | D9 | Assignment condition: a new owner decision returns it to current execution; [detail](#m6---runtime-only-slim-image-variant) |
| Runtime | M7 | Include the `tools` IOC generator in the images | Milestone | Deferred | No | D10 | Assignment condition: a new owner decision returns it to current execution; [detail](#m7---include-the-tools-ioc-generator) |
| Runtime | M8 | Pin `con` and `procServ-env` to a released version | Milestone | Conditional | No | D11 | Condition: `procServ-env` publishes a version number; [detail](#m8---pin-con-and-procserv-env) |

Backlog tally: 5 rows - Open 1, Deferred 3, Conditional 1.

### Backlog Details

#### M4 - Modernize the mdbook image

Origin: 5c186b4 / M4
Identity History: none
GitHub Issue: #32, https://github.com/jeonghanlee/Dockerfiles/issues/32
Status: Open

##### Summary

The mdbook image is the one remaining non-EPICS image in the repository. It was
left untouched by the 2026 rework and is scheduled independently of it.

##### Scope

Rebuild the mdbook image on a current base with a pinned mdbook release.

Out of scope: the three EPICS images.

##### Completion Criteria

- The image builds with the latest pinned mdbook and renders a site through the
  GitLab Pages template flow.

##### Dependencies And Decisions

- none

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope when the owner schedules the work.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Build and render | Build the image, then render a site through the GitLab Pages template flow | mdbook image | Build succeeds and the site renders |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | mdbook image | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Modernize the mdbook image
Labels: enhancement
GitHub Milestone: 2.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 2.0.0
Last Compared: 2026-08-14, register reset

#### M5 - Image vulnerability scanning

Origin: 5c186b4 / M5
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

Report-only vulnerability scanning of the built images. Deferred because the
findings are dominated by base-OS packages that this repository cannot act on
(D8).

##### Scope

Add a report-only scan of the built images to the build flow.

Out of scope: gating a build or a publish on scan findings.

##### Completion Criteria

- Defined when the work is picked up.

##### Dependencies And Decisions

- D8 defers the row.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope when a new owner decision returns the row to execution.

##### Test Plan

No local check exists yet. The Test Plan is written when the row is assigned
and its Completion Criteria are defined.

##### Verification Results

Not run. The row is unassigned.

##### Closure Evidence

- none

#### M6 - Runtime-only slim image variant

Origin: 5c186b4 / M6
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

A second image design carrying no compiler and no `-devel` packages, for pure
IOC execution rather than runner builds, published under its own tag. It is the
second half of the package-footprint split recorded as D9; the first half,
pruning pure surplus while keeping the runner toolchain, already shipped.

##### Scope

A separate runtime-only image with the minimal NEEDED set and its own tag.

Out of scope: the existing dev-carrying images.

##### Completion Criteria

- Defined when the work is picked up.

##### Dependencies And Decisions

- D9 defers the row.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope when a new owner decision returns the row to execution.

##### Test Plan

No local check exists yet. The Test Plan is written when the row is assigned
and its Completion Criteria are defined.

##### Verification Results

Not run. The row is unassigned.

##### Closure Evidence

- none

#### M7 - Include the tools IOC generator

Origin: 5c186b4 / M7
Identity History: none
GitHub Issue: none
Status: Deferred

##### Summary

The `tools` IOC generator was deferred out of the runtime layer by owner
decision (D10) and held here.

##### Scope

Ship the `tools` IOC generator inside the three EPICS images.

Out of scope: procServ and con, which already ship.

##### Completion Criteria

- Inside a container, generate an IOC, build it, and start it.

##### Dependencies And Decisions

- D10 defers the row.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the scope when a new owner decision returns the row to execution.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container runtime | Generate an IOC with the tools generator, build it, and start it inside a container | All three EPICS images | Generation, build, and start all succeed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | All three EPICS images | Pending | none |

##### Closure Evidence

- none

#### M8 - Pin con and procServ-env

Origin: 5c186b4 / M8
Identity History: none
GitHub Issue: none
Status: Conditional

##### Summary

Both `con` and `procServ-env` are cloned at floating default-branch HEAD, with
the clone commit recorded in the bake manifest. They stay unpinned until
`procServ-env` publishes a version number (D11).

##### Scope

Pin both clones to a tag or commit in all three Dockerfiles and record the pin
in the bake manifest.

Out of scope: pinning the EPICS distribution, which is already fixed by
`DIST_VERSION`.

##### Completion Criteria

- Both clones are pinned in all three Dockerfiles and the pin appears in the
  bake manifest.

##### Dependencies And Decisions

- D11 holds the row Conditional. The named observable condition is a published
  `procServ-env` version number. When observed, move the row to Not started.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Pin both clones once the condition is observed.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Build and manifest | Build each image and read the bake manifest | All three EPICS images | The manifest records the pinned con and procServ-env references |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | All three EPICS images | Pending | none |

##### Closure Evidence

- none

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-08-14 | 5c186b4ccde99a27bc32c5a60c759d076a7221cd |
