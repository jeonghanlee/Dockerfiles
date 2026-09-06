# Work Register

Release line: master
Milestone index: 69b9303
Canonical path: `docs/milestone-69b9303.md`
Canonical branch or ref: master
Git upstream: origin/master
Remote tracker: jeonghanlee/Dockerfiles, GitHub milestone 1.0.0 ("Lean images, everlasting EPICS")

Next session entry point: no Ready row remains. The s6 supervision suite (M4)
and the Ubuntu 24.04 image (M5) shipped at image version 1.0.0 on
EPICS-env-distribution 1.2.2, published and verified on 2026-09-05 with issues
#38 and #39 closed. The remaining work is gated: M1 carries the ioc-runner
supervision layer and is Blocked on G1, with M7 (runtime-only slim image)
following it; M6 (Ubuntu 26.04) and M8 (distribution 1.3.0 bump) are Blocked on
G4 until that version publishes. The mdbook image (M2) and the documentation
site (M3) are complete.

This register is the status source of truth for the remaining master work after
the 1.2.2 release. It replaces `docs/milestone-5c186b4.md`, whose completed rows
and decision records stay reachable at commit 69b9303.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime | M1 | Container runtime: the ioc-runner supervision layer | Carry-forward | Blocked | No | G1 | ioc-runner starts and stops an IOC in a container that runs no systemd, on every EPICS image; [detail](#m1---container-runtime) |
| Images | M2 | Modernize the mdbook image | Milestone | Complete | No | | Image builds with the latest pinned mdbook and renders a site through the GitLab Pages flow; [detail](#m2---modernize-the-mdbook-image) |
| Documentation | M3 | Publish repository documentation with mdBook and GitHub Pages | Milestone | Complete | No | G3 | The fixed mdBook image renders the repository book, the Actions workflow deploys it, and the live URL serves the result; [detail](#m3---publish-repository-documentation) |
| Gates | G1 | epics-ioc-runner container execution mode | External gate | Open | No | | Upstream issue jeonghanlee/epics-ioc-runner#127 resolved; [detail](#g1---epics-ioc-runner-container-mode) |
| Gates | G2 | GitLab consumer cutover | External gate | Open | No | | Consumer rollout of the published images, executed in `alsu/ci`, with no work row here; [detail](#g2---gitlab-consumer-cutover) |
| Gates | G3 | GitHub Pages Actions source | External gate | Complete | No | | Repository Pages source reports `build_type: workflow`; [detail](#g3---github-pages-actions-source) |
| Runtime | M4 | s6 supervision suite in the EPICS images | Milestone | Complete | No | | The six supervision binaries the runner uses are on PATH in every EPICS image and the image gate checks them; [detail](#m4---s6-supervision-suite) |
| Images | M5 | Ubuntu 24.04 EPICS image | Milestone | Complete | No | | `jeonghanlee/ubuntu24-epics` builds from the distribution `ubuntu-24.04` tree and passes the image gate; [detail](#m5---ubuntu-2404-epics-image) |
| Images | M6 | Ubuntu 26.04 EPICS image | Milestone | Blocked | No | G4 | `jeonghanlee/ubuntu26-epics` builds from the 1.3.0 distribution `ubuntu-26.04` tree and passes the image gate; [detail](#m6---ubuntu-2604-epics-image) |
| Runtime | M7 | Runtime-only slim image | Milestone | Not started | No | M1 | A toolchain-free image builds with the minimal set, carries its own tag, and runs an IOC through ioc-runner; [detail](#m7---runtime-only-slim-image) |
| Images | M8 | Move the EPICS images to distribution 1.3.0 | Milestone | Blocked | No | G4 | The four images on distribution 1.2.2 build from distribution 1.3.0 and pass the image gate; [detail](#m8---distribution-130-image-bump) |
| Gates | G4 | EPICS-env-distribution 1.3.0 | External gate | Open | No | | Distribution 1.3.0 is published and carries an `ubuntu-26.04` tree; [detail](#g4---epics-env-distribution-130) |

Tally: 8 milestone rows - Complete 4, In progress 0, Blocked 3, Not started 1,
Ready 0. External gates: 3 open (G1, G2, G4) and 1 complete (G3).
Backlog is reported separately below and excluded from this tally.

### Milestone Details

#### M1 - Container runtime

Origin: 69b9303 / M1
Identity History: none
GitHub Issue: #28, https://github.com/jeonghanlee/Dockerfiles/issues/28
Status: Blocked

##### Summary

The images ship procServ and con for direct IOC execution today; ioc-runner
stays excluded until it gains a container execution mode that does not require
systemd, tracked upstream as G1. This row covers reintroducing ioc-runner into
the EPICS images as a supervision layer: the runner installed from a pinned
upstream ref, its container setup mode run at image build, and an entry point
that runs the s6 supervision tree as PID 1. The runtime-only slim image was
carried in this row until 2026-09-03 and is now M7.

##### Scope

Install epics-ioc-runner from a pinned upstream ref through its Makefile, run
its container setup mode at image build so the service account, group,
configuration directory, and CLI are present, and give the image an entry point
that creates the scan directory and runs `s6-svscan` as PID 1. Verify IOC start
and stop inside a container on every EPICS image.

Out of scope: the upstream ioc-runner change itself (G1); the s6 supervision
binaries the layer runs on (M4); the runtime-only slim image (M7); the package
sets of the existing dev-carrying images.

##### Completion Criteria

- ioc-runner starts and stops an IOC inside a container that runs no systemd,
  on every EPICS image.
- The image entry point runs `s6-svscan` as PID 1 and IOC output reaches
  container stdout.

##### Dependencies And Decisions

- G1 must be Complete before work resumes; resume as Not started when G1 is
  Complete.
- M4 supplies the supervision binaries this layer runs on and must be Complete
  first.
- Direct procServ and con execution covers container IOC use meanwhile, so the
  images are usable without ioc-runner until then.
- The runner contract uses only the s6 supervision binaries, never the
  s6-overlay entry point and never s6-rc. Stated by the epics-ioc-runner owner
  on 2026-09-03.
- The upstream container mode is implemented on a branch and is absent from
  master and from the 1.3.0 release, so there is no pinnable released ref yet.
  Observed 2026-09-03.
- The entry point must create the scan directory itself. A directory made at
  image build time under `/run` does not survive a runtime that mounts `/run`
  as tmpfs, so the build-time copy is a convenience only.
- The container mode is root-only and refuses to run without a live
  `s6-svscan` on the scan directory, which fixes the entry point as PID 1
  rather than an optional wrapper.
- The upstream lifecycle suite needs `CAP_SYS_PTRACE` inside the container for
  its deep inspect check, so a verification run adds that capability.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Pin the upstream ref once the container execution mode is released, and
   install the runner through its Makefile.
2. Run the container setup mode at image build so the service account, group,
   configuration directory, and CLI are present, with no sudoers entry, no unit
   template, and no log rotation.
3. Add the entry point that creates the scan directory and runs `s6-svscan` as
   PID 1, with the container running as root.
4. Verify IOC start and stop on every EPICS image.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container runtime | Start and stop an IOC through ioc-runner in a running container | Every EPICS image | Start and stop both succeed with no systemd present |
| T2 | Supervision entry | Run the image entry point and inspect PID 1 and IOC output | Every EPICS image | PID 1 is `s6-svscan` and IOC output reaches container stdout |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Every EPICS image | Pending | none |
| T2 | Not run | Every EPICS image | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add the ioc-runner container supervision layer
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-09-03, after the issue rewrite
Scope note: issue #28 was filed as the whole IOC runtime layer - procServ, con,
ioc-runner, and the tools IOC generator. procServ and con shipped at 1.2.2 and
the tools generator was retired 2026-08-17, so its title and body were narrowed
on 2026-09-03 to the remaining ioc-runner half that this row covers.

#### M2 - Modernize the mdbook image

Origin: 69b9303 / M2
Identity History: none
GitHub Issue: #32, https://github.com/jeonghanlee/Dockerfiles/issues/32
Status: Complete

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

- Image modernized to mdbook 0.5.4 on the trixie base, PDF tools kept, publish
  gated on `workflow_dispatch`; commits 401b202 (image) and 1047990 (register).
- Published to Docker Hub via the gated `workflow_dispatch` on 2026-08-17
  (`jeonghanlee/mdbook:latest`, ~191 MB, down from ~352 MB).
- Consumer verification: EPICS-env is unaffected (no `git-repository-icon`
  line); epics-trainings was adapted to mdbook 0.5 (icon `fab-` prefix in both
  configs, rustc check removed from its Pages workflow) and renders 33 pages on
  the new image.

##### GitHub Projection

Title: Modernize the mdbook image
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-08-17, register reset
Close note: #32 can be closed on the completed modernization and publish; the
close is an owner-run gh action, not yet performed.

#### M3 - Publish repository documentation

Origin: 69b9303 / M3
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

The repository documentation is organized as an mdBook, rendered with the
fixed `jeonghanlee/mdbook:0.5.4` image, validated through local and GitHub
Actions paths, and published at
https://jeonghanlee.github.io/Dockerfiles/.

##### Scope

Maintain the repository mdBook source, local link validation, fixed-image
rendering, GitHub Actions build and deployment, and the published Pages site.

Out of scope: consumer documentation repositories, mdbook image modernization
owned by M2, and custom domain configuration.

##### Completion Criteria

- The repository validation and fixed-image mdBook render pass.
- The Documentation workflow builds and deploys the Pages artifact.
- Pages uses the GitHub Actions source and the live URL serves the mdBook.

##### Dependencies And Decisions

- G3 is Complete.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-19, in session
Implementation Authorization: owner, 2026-08-19, in session
Superseded Plan Artifacts: none

1. Organize setup, architecture, maintenance, historical, and work-register
   documents under the mdBook source tree.
2. Add fixed-image rendering and local Markdown link validation.
3. Add the GitHub Pages workflow, select the Actions source, and verify the
   deployed site.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Repository validation | Run `make check` | Debian 13 host | Source, workflow, link, and dry-run checks pass |
| T2 | Documentation render | Run `make docs` through the repository target | Docker with `jeonghanlee/mdbook:0.5.4` | Complete book renders into `public/` |
| T3 | CI deployment | Run the Documentation workflow from the committed tree | GitHub Actions, `ubuntu-22.04` | Build and deploy jobs pass |
| T4 | Published site | Request the Pages root and inspect the returned document | GitHub Pages | HTTP 200 response contains the mdBook site |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-19 | Debian 13 host | Pass | `make check` completed successfully |
| T2 | 2026-08-19 | Docker, `jeonghanlee/mdbook:0.5.4` | Pass | Seven chapters rendered and generated local links passed |
| T3 | 2026-08-19 | GitHub Actions, `ubuntu-22.04` | Pass | Documentation run 32326076508 completed build and deploy jobs |
| T4 | 2026-08-19 | GitHub Pages | Pass | Live root returned HTTP 200 with the mdBook title and assets |

##### Closure Evidence

- Commit 7377dd1 added the documentation source, validation, fixed renderer,
  and Pages workflow.
- Documentation workflow run 32326076508 built and deployed the committed
  tree successfully.
- The Pages API reported `build_type: workflow` on 2026-08-19, closing G3.
- https://jeonghanlee.github.io/Dockerfiles/ served the mdBook with HTTP 200 on
  2026-08-19.

#### M4 - s6 supervision suite

Origin: 69b9303 / M4
Identity History: none
GitHub Issue: #38, https://github.com/jeonghanlee/Dockerfiles/issues/38
Status: Complete

##### Summary

The ioc-runner container execution mode supervises procServ with s6 instead of
systemd, so the EPICS images must carry the s6 supervision binaries before that
runtime can be exercised on them. The runner uses `s6-svscan`, `s6-supervise`,
`s6-svc`, `s6-svstat`, `s6-svscanctl`, and `s6-setuidgid`, with `s6-svok`
welcome, and depends on neither the s6-overlay entry point nor s6-rc. The
version floor is s6 2.13.

##### Scope

Add the s6 supervision suite to the three EPICS image builds so the required
binaries are on PATH, by two routes that meet the same 2.13 floor: the
distribution package on Debian 13, and a source build of skalibs, execline, and
s6 on the two Rocky images. Keep the full s6 toolset in both routes. Record the
s6 delivery in the bake manifest, and extend the image verification gate with a
check that each binary is present and runnable.

Out of scope: the ioc-runner layer that consumes these binaries (M1); the
s6-overlay entry point and s6-rc, which the runner contract excludes; the Ubuntu
images (M5, M6), which take the matching route on their own rows; the mdbook
image.

##### Completion Criteria

- `s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`, `s6-svscanctl`, and
  `s6-setuidgid` resolve on PATH in every EPICS image, at s6 2.13 or later.
- The image verification gate fails when any of the six entry-point binaries
  is missing or not runnable, or when a real supervision cycle - service up,
  `s6-svc -wD` stop, `s6-svscanctl -t` teardown - does not complete.
- The bake manifest records the s6 components and their source revisions.

##### Dependencies And Decisions

- None. The work depends on no other row and no open gate.
- Requested by the epics-ioc-runner owner on 2026-09-03 as the precondition for
  that repository's container lifecycle test. It does not block the upstream
  implementation, only its verification on these images.
- The upstream lifecycle suite passed in `jeonghanlee/debian13-epics` with s6
  2.13.1.0 added by hand for the run; the Rocky images are unrun because they
  carry no s6. Reported by the epics-ioc-runner owner, 2026-09-03.
- Package availability differs per base: Debian 13 packages s6 2.13.1.0 and
  execline 2.9.6.1; Ubuntu 26.04 packages the same versions; Ubuntu 24.04
  packages s6 2.12.0.3, below the floor; Rocky 8.10 and 10.2 carry no s6,
  execline, or skalibs in BaseOS, AppStream, or EPEL. Observed 2026-09-03.
- The layer does not depend on a distribution bump and can be built and gated
  first, which is why this row stayed independent of G4. The images originally
  published under `DIST_VERSION`; the `IMAGE_VERSION` split (d0e338d) then made
  the publish tag independent, and the layer shipped at image version 1.0.0 on
  distribution 1.2.2.
- Delivery route, accepted 2026-09-04: the distribution package where it meets
  the floor, a source build where it does not. Debian 13 installs the `s6` and
  `execline` packages together in the OS package layer; Rocky 8.10 and 10.2
  build skalibs, execline, and s6 from pinned tags, statically linked, then drop
  the libraries, headers, and sources in that one layer, mirroring the
  procServ-env layer.
- Version pinned to s6 2.13.1.0 with execline 2.9.6.1, which is what apt
  provides on Debian 13, so the package and source routes ship the identical s6
  and execline. The source build adds skalibs 2.14.3.0 internally; it is static
  and not shipped.
- The full s6 toolset is kept, not pruned to the named binaries. A prune to the
  seven binaries was tested on both Rocky images on 2026-09-04 and broke the
  lifecycle: the service did not start and `s6-svc -wD` died with `unable to
  exec s6-svlisten1`, because the named tools exec other s6 binaries at run
  time. Keeping the full set costs about 3.5 MB per Rocky image.
- Both routes were validated in base images on 2026-09-04. `s6-svscan`
  supervised a service that dropped to `ioc-srv:ioc` through `s6-setuidgid`, its
  stdout reached the svscan stdout, `s6-svc -wD` stopped it with no orphan, and
  `s6-svscanctl -t` tore the tree down. Confirmed on debian:trixie-slim and
  ubuntu:26.04 by package, and on rockylinux:8.10, rockylinux:10.2, and
  ubuntu:24.04 by source build. This validates the route, not the shipped
  images; T1 and T2 run against the built EPICS images.
- Gate strategy, decided 2026-09-05 after a coherence review: the six s6
  binaries the runner names are its entry points, not a sufficiency set. A
  prune to those six plus `s6-svok` broke the lifecycle (`s6-svc -wD` execs
  `s6-svlisten1`, and the service did not start), and the true exec closure was
  never measured; the full toolset ships for that reason. So G9 asserts the
  entry points for a precise diagnostic, and G11 asserts sufficiency by
  behaviour: a real `s6-svscan` tree, a service dropped to `nobody` through
  `s6-setuidgid`, stopped with `s6-svc -wD -T`, torn down with
  `s6-svscanctl -t`. Observed 12/12 on all four images on 2026-09-05.
- The 2.13 version floor needs no separate numeric check: the options G11
  exercises (`-wD -T`, `-o`) are the ones that fixed the floor, so a sub-floor
  s6 fails G11. Skarnet tools print no version and the apt and source routes
  record it differently, so a numeric check would be redundant and uneven.
- The debian13 apt route is explained in its package-layer comment, matching
  the source-build comment on the other images; its three unused s6 version
  ARGs were removed, and its manifest records the apt `s6` and `execline`
  package versions so every image records its s6 delivery.
- The Dockerfile header version is a file-generation marker distinct from
  `IMAGE_VERSION`, kept as two axes (recorded in CLOSED_DOORS). It moves to
  2.1.0 for this generation's s6 and version-split additions, and gate.bash
  to 0.3.0 for G11.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-09-04, in session
Implementation Authorization: none
Superseded Plan Artifacts: none

1. On Debian 13, install the `s6` and `execline` packages together in the OS
   package layer.
2. On Rocky 8.10 and 10.2, build skalibs 2.14.3.0, execline 2.9.6.1, and s6
   2.13.1.0 from pinned tags in one layer, statically linked, then remove the
   libraries, headers, and sources in that layer.
3. Record the s6 delivery in the bake manifest: the source revisions on the
   Rocky images, the package version on Debian 13.
4. Extend `gate.bash` with a check that the required binaries are present and
   runnable.
5. Build the three images and run the gate.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Image build | Build every EPICS image and run the verification gate | debian13, rocky8, rocky10 images | The gate reports the s6 entry points present and the supervision cycle passing |
| T2 | Supervision runtime | Run `s6-svscan` on a scan directory and drive one procServ service through `s6-svc` and `s6-svstat` | The three EPICS images | The service starts under the service account, IOC output reaches stdout, and stop terminates procServ and its child |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-05 | debian13, rocky8, rocky10 images | Pass, gate 12/12 | Local `make gate.<image>` and CI on PR #42, merged in 1065267 |
| T2 | 2026-09-05 | Published 1.0.0 images: debian13, rocky8, rocky10 | Pass, 9/9 | procServ under s6-svscan ran as ioc-srv; `s6-svc -wD -d` stopped procServ and softIoc with no orphan |

##### Closure Evidence

- Delivered in 0de6589 (s6 layers), 58ab953 (debian13 apt route), and 7ea1657
  (gate G9 and G11); merged to master in 1065267 and published as the 1.0.0
  image tags on 2026-09-05. Issue #38 closed 2026-09-05.

##### GitHub Projection

Title: Add the s6 supervision suite to the EPICS images
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: closed
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-09-05, at close

#### M5 - Ubuntu 24.04 EPICS image

Origin: 69b9303 / M5
Identity History: none
GitHub Issue: #39, https://github.com/jeonghanlee/Dockerfiles/issues/39
Status: Complete

##### Summary

EPICS-env-distribution publishes an `ubuntu-24.04` tree next to the trees the
three existing EPICS images consume, so an Ubuntu image needs no distribution
work of its own. The image pins distribution 1.2.2, which already carries the
tree. Since d0e338d the images publish under their own `IMAGE_VERSION`, so this
image shipped at image version 1.0.0 on 1.2.2 and no longer waits on a
distribution bump.

##### Scope

Add an `ubuntu24` image directory whose Dockerfile follows the established
pattern - OS package layer, sparse distribution fetch, procServ and con built
from source, the s6 supervision binaries, the baked environment, and the
`setEnv` contract. Register the directory in the image directory lists, add the
thin per-OS workflow that calls the reusable image workflow, and add the image
to the repository documentation tables.

Out of scope: the Ubuntu 26.04 image (M6); any change to the distribution
itself; publishing, which stays an owner-run `workflow_dispatch`.

##### Completion Criteria

- `make build.ubuntu24` produces the image from distribution 1.2.2 and
  `make gate.ubuntu24` passes every check.
- The per-OS workflow builds and gates the image in CI.
- The README and architecture tables list the image and its Docker Hub name.

##### Dependencies And Decisions

- No open gate. The image was pinned to `DIST_VERSION` 1.2.2, the version the
  three existing images consume, which already carries the `ubuntu-24.04` tree.
- The `IMAGE_VERSION` split (d0e338d) decoupled the publish tag from
  `DIST_VERSION`, so this image entered the set at image version 1.0.0 on 1.2.2
  and did not wait on the 1.3.0 distribution bump; that bump is M8.
- Ubuntu 24.04 packages s6 2.12.0.3, below the runner's 2.13 floor, so this
  image takes the same source-built s6 route as the Rocky images rather than its
  own package set. Observed 2026-09-03.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-09-05, in session
Implementation Authorization: owner, 2026-09-05, in session
Superseded Plan Artifacts: none

1. Add `ubuntu24/Dockerfile` from the debian13 pattern, with the Ubuntu 24.04
   base, `DIST_VERSION` 1.2.2, and the `ubuntu-24.04` distribution tree.
2. Register the directory in `IMAGE_DIRS` and `RELEASE_IMAGE_DIRS`.
3. Add the thin per-OS workflow with the image name
   `jeonghanlee/ubuntu24-epics`.
4. Add the image to the README and architecture tables.
5. Build and gate locally, then in CI.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Image build | Run the repository build and gate targets for the image | Debian 13 host with Docker | Build succeeds and every gate check passes |
| T2 | CI | Run the per-OS workflow from the committed tree | GitHub Actions | Build and gate jobs pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-05 | Debian 13 host with Docker | Pass, gate 12/12 | Local `make build.ubuntu24` and `make gate.ubuntu24` |
| T2 | 2026-09-05 | GitHub Actions | Pass | ubuntu24 workflow on PR #42, merged in 1065267 |

##### Closure Evidence

- Delivered in 96fa07a (image, workflow, configure entries) and ea3924e
  (documentation tables); merged to master in 1065267 and published as
  `jeonghanlee/ubuntu24-epics:1.0.0` on 2026-09-05. Issue #39 closed 2026-09-05.
- The s6 supervision cycle also ran on the published ubuntu24 1.0.0 image on
  2026-09-05: procServ under s6-svscan started as ioc-srv and stopped cleanly,
  9/9.

##### GitHub Projection

Title: Add the Ubuntu 24.04 EPICS image
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: closed
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-09-05, at close

#### M6 - Ubuntu 26.04 EPICS image

Origin: 69b9303 / M6
Identity History: none
GitHub Issue: #40, https://github.com/jeonghanlee/Dockerfiles/issues/40
Status: Blocked

##### Summary

Ubuntu 26.04 LTS is the next long-term base and packages s6 2.13.1.0 and
execline 2.9.6.1, which meet the supervision-version floor the container
runtime needs. The image pins distribution 1.3.0, which is unpublished and is
the version expected to carry the `ubuntu-26.04` tree; that condition is G4.

##### Scope

Add an `ubuntu26` image directory in the same shape as M5, pinned to
`DIST_VERSION` 1.3.0, with its per-OS workflow, image directory registration,
and documentation entries.

Out of scope: the distribution work that adds the tree (G4); the Ubuntu 24.04
image (M5).

##### Completion Criteria

- `make build.ubuntu26` produces the image from distribution 1.3.0 and
  `make gate.ubuntu26` passes every check.
- The per-OS workflow builds and gates the image in CI.
- The README and architecture tables list the image and its Docker Hub name.

##### Dependencies And Decisions

- G4 must be Complete before work resumes; resume as Not started when G4 is
  Complete.
- The image pins `DIST_VERSION` 1.3.0, the version the owner expects to carry
  the `ubuntu-26.04` tree, stated 2026-09-03.
- Ubuntu 26.04 packages s6 2.13.1.0 and execline 2.9.6.1, which meet the
  runner's floor. Observed 2026-09-03.
- M5 establishes the Ubuntu image pattern this row follows.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Add `ubuntu26/Dockerfile` following the Ubuntu 24.04 image, with the Ubuntu
   26.04 base, `DIST_VERSION` 1.3.0, and the `ubuntu-26.04` distribution tree.
2. Keep the directory out of the build and gate lists until the distribution
   tree exists, so CI does not fail on a fetch that cannot succeed.
3. Add the thin per-OS workflow with the image name
   `jeonghanlee/ubuntu26-epics`.
4. Register the directory and add the documentation entries when G4 completes.
5. Build and gate locally, then in CI.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Image build | Run the repository build and gate targets for the image | Debian 13 host with Docker | Build succeeds and every gate check passes |
| T2 | CI | Run the per-OS workflow from the committed tree | GitHub Actions | Build and gate jobs pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Debian 13 host with Docker | Pending | none |
| T2 | Not run | GitHub Actions | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add the Ubuntu 26.04 EPICS image
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-09-03, at issue creation

#### M7 - Runtime-only slim image

Origin: 69b9303 / M7
Identity History: separated from M1 on 2026-09-03; M1 retains the ioc-runner
supervision layer
GitHub Issue: none
Status: Not started

##### Summary

The published images carry the consumer build toolchain because runner jobs
compile IOCs inside the running container. A pure IOC execution host needs none
of it. This row defines and builds a toolchain-free image with the minimal set
under its own tag, the counterpart to the dev-carrying images shipped at 1.2.2.

##### Scope

Define the minimal runtime package set, build the slim image under its own tag,
and run an IOC on it through ioc-runner.

Out of scope: the ioc-runner supervision layer itself (M1); the package sets of
the dev-carrying images, already pruned at 1.2.2.

##### Completion Criteria

- The slim image builds with the minimal set and carries its own tag.
- An IOC starts and stops on the slim image through ioc-runner.

##### Dependencies And Decisions

- M1 must be Complete first; the slim image runs IOCs through the supervision
  layer M1 delivers.
- The first half of the package-footprint split - pruning surplus while keeping
  the runner toolchain - shipped in the 1.2.2 images.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the minimal runtime set once the supervision layer exists.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Image build | Build the slim image with the minimal set | Slim runtime image | Image builds and carries its own tag |
| T2 | Container runtime | Start and stop an IOC through ioc-runner on the slim image | Slim runtime image | Start and stop both succeed |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Slim runtime image | Pending | none |
| T2 | Not run | Slim runtime image | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Build a runtime-only slim EPICS image
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M8 - Distribution 1.3.0 image bump

Origin: 69b9303 / M8
Identity History: none
GitHub Issue: #41, https://github.com/jeonghanlee/Dockerfiles/issues/41
Status: Blocked

##### Summary

Four EPICS images pin `DIST_VERSION` 1.2.2 - debian13, rocky8, rocky10, and
ubuntu24 - the value that selects the prebuilt EPICS tree and sets the build
version label. Since the `IMAGE_VERSION` split (d0e338d), `DIST_VERSION` no
longer names the publish tag, so this bump is about consuming the newer 1.3.0
EPICS tree, not unifying versions. The Ubuntu 26.04 image (M6) is created
directly at 1.3.0.

##### Scope

Move `DIST_VERSION` to 1.3.0 across the four image Dockerfiles pinned to 1.2.2
through the repository's coordinated bump target, re-check the container gate's
expected module count against the 1.3.0 tree, and update the maintenance guide
where it names the current version in its worked example.

Out of scope: the Ubuntu 26.04 image, which is created at 1.3.0 by M6; the
s6 supervision layer (M4); publishing, which stays an owner-run
`workflow_dispatch`.

##### Completion Criteria

- The four images build from distribution 1.3.0 and pass every container gate
  check.
- The per-OS workflows build and gate the images in CI.
- The module inventory check passes against the 1.3.0 tree, with its expected
  count updated if the tree changed.

##### Dependencies And Decisions

- G4 must be Complete before work resumes; resume as Not started when G4 is
  Complete.
- The container gate compares the module directory entry count against a
  constant pinned to the current distribution, so a 1.3.0 tree with a different
  module set fails that check until the constant is updated.
- The bump target rewrites every release image directory at once, so it covers
  debian13, rocky8, rocky10, and ubuntu24 together; ubuntu26 joins once M6
  registers it.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Run the coordinated bump target for 1.3.0 and review all four Dockerfile
   changes.
2. Re-check the gate's expected module count against the 1.3.0 tree and update
   it when the tree changed.
3. Update the maintenance guide's worked example version.
4. Build and gate locally, then in CI.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Image build | Build the four images and run the verification gate | debian13, rocky8, rocky10, ubuntu24 images | Build succeeds and every gate check passes against the 1.3.0 tree |
| T2 | CI | Run the per-OS workflows from the committed tree | GitHub Actions | Build and gate jobs pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | debian13, rocky8, rocky10 images | Pending | none |
| T2 | Not run | GitHub Actions | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Move the EPICS images to distribution 1.3.0
Labels: enhancement
GitHub Milestone: 1.0.0
Observed State: open
Observed Labels: enhancement
Observed Milestone: 1.0.0
Last Compared: 2026-09-04, at issue creation

#### G1 - epics-ioc-runner container mode

Origin: 69b9303 / G1
GitHub Issue: jeonghanlee/epics-ioc-runner#127
Status: Open

##### Summary

ioc-runner needs a container execution mode that does not require systemd
before M1 can proceed. The work is owned by the `epics-ioc-runner` repository.
The mode adds a `--container` form to both the runner and its setup script: s6
supervises procServ with one service directory per IOC, the setup form creates
the accounts, configuration directory, and scan skeleton without a sudoers
entry, unit template, or log rotation, and the runner requires root and a live
`s6-svscan` on the scan directory. It is implemented on an upstream branch and
is neither merged nor released.

##### Completion Criteria

- epics-ioc-runner#127 is resolved and a container execution mode is released.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-03 | Pending | epics-ioc-runner 1.3.0 published without the container setup mode - its `setup-system-infra.bash` accepts only `--full`; jeonghanlee/epics-ioc-runner#127 remains open in the Backlog milestone |
| 2026-09-03 | Pending | Container mode implemented on the upstream branch `feature/container-execution` at commit add145f, carrying `--container` in the runner and the setup script plus a container lifecycle suite; not merged, no pull request open, and jeonghanlee/epics-ioc-runner#127 still open |

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

#### G3 - GitHub Pages Actions source

Origin: 69b9303 / G3
GitHub Issue: none
Status: Complete

##### Summary

The repository owner selects GitHub Actions as the Pages publishing source so
the legacy branch-based Jekyll workflow no longer owns publication for M3.

##### Completion Criteria

- The repository Pages API reports `build_type: workflow`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-08-19 | Pass | `gh api repos/jeonghanlee/Dockerfiles/pages` reported `build_type: workflow` |

##### Closure Evidence

- The Pages source was changed to GitHub Actions and verified on 2026-08-19.

#### G4 - EPICS-env-distribution 1.3.0

Origin: 69b9303 / G4
GitHub Issue: none
Status: Open

##### Summary

Both Ubuntu images pin `DIST_VERSION` 1.3.0, which supplies the prebuilt
binaries, the build version, and the publish tag. That distribution version is
unpublished: 1.2.2 is the only published one, and it carries `debian-13`,
`rocky-8.10`, `rocky-10.2`, and `ubuntu-24.04` but no `ubuntu-26.04`. The work
is owned by the EPICS-env-distribution repository.

##### Completion Criteria

- EPICS-env-distribution 1.3.0 is published and carries an `ubuntu-26.04` tree.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-04 | Pending | Distribution 1.2.2 is the only published version; it carries no `ubuntu-26.04` tree and 1.3.0 does not exist |

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
