# Work Register

Repository-local canonical tracker for the 2026 image rework in `Dockerfiles`.
This register is agent-independent: every agent and contributor reads this file
instead of chat history or per-agent memory.

Goal: rebuild the repository images as EPICS-environment-only containers for
debian13, rocky 8.10, and rocky 10.x (latest), consuming the prebuilt
`EPICS-env-distribution` binaries. Purposes: (1) GitLab runner, (2) container
IOC execution, (3) test environments.

Mode: register-authoritative — this register is the status source of truth.
The cycle is mirrored to GitHub milestone `2.0.0` ("Lean images, everlasting
EPICS") as issues #26-#32, one per M-group; issue closure follows the register.

## Format

- Two levels: `M<group>` (workstream) / `M<group>.<task>` (work unit).
  Verification and evidence live in the task's Done-when column.
- Tracking IDs: **M** (work) · **G** (external gate) · **D** (decision).
- Dependencies are typed arrows: `← M..` (prior task) · `← G..` (external gate)
  · `← D..` (decision).
- Status (✅ done · 🔄 in progress · ⬜ not started · 🔒 blocked) and Next
  (▶ ready — startable now) are kept separate. A group's status and the ready
  set derive from its tasks and the dependency arrows.
- Work proceeds on the `legacy-trim` branch; merges to master follow the
  git-workflow execution policy.

## Now / Next (2026-07-18)

```
In progress (🔄):  M5.1 (scheme settled as D10; consistency application rides M5.2)
Done 2026-07-18:   M1 complete · G1 (tag 1.2.0) · review session rs20260718_025216 converged
                   · morning decision packet FULLY resolved (D8-D15) · D2/D3 ratified
                   · RELEASE.md removed (D11) · rocky10-epics.yml authored in ci repo (D13)

Next entry points:
  ▶ ready now:   M2.1 (debian13 Dockerfile rewrite per enriched task row)
  planned order: M2.1 → M2.2 · M2.3 → M2.4 → M3.1 · M3.2 → M4.1 → M5.2 → M4.2 → [G2] M5.3 → M6.1

External wait:  M5.3 ← G2 (Docker Hub publish) · M3.3 ← G3 (epics-ioc-runner#127) · M2 rollout ← G4 (consumer cutover, D13)
Operator action:  none standing (G2 arrives at M5.3; G4 sequencing planned after M2)

Next session entry point: start M2.1 — rewrite `debian13/Dockerfile` per its
enriched task row (distribution 1.2.1 pin, sparse fetch, ENV bake list,
resident toolchain per D2).
```

Tally: 18 tasks — ✅ 3 · 🔄 1 · ⬜ 12 · 🔒 2 / ready(▶) 1 · external gates 4 (G1 satisfied · G2·G3·G4 open)

## Groups (L1)

| Group | Name | Progress | Status | Next |
| :-- | :-- | :-- | :-- | :-- |
| M1 | Legacy trim (#26) | 3/3 | ✅ | |
| M2 | Distribution-based images (#27) | 0/4 | ⬜ | ▶ M2.1 |
| M3 | IOC runtime layer (#28) | 0/3 | ⬜ | |
| M4 | Verification gates (#29) | 0/2 | ⬜ | |
| M5 | CI and publish (#30) | 0/3 | ⬜ | ▶ M5.1 |
| M6 | Documentation (#31) | 0/1 | ⬜ | |
| M7 | Deferred follow-ups (#32) | 0/1 | ⬜ | |

## Tasks (L2)

The `Group` cell is written once per group (continuation rows are blank).

| Group | ID | Task | Status | Next | Deps | Done when / Evidence |
| :-- | :-- | :-- | :-- | :-: | :-- | :-- |
| M1 Legacy trim | M1.1 | Author this register on `legacy-trim` | ✅ | | | Register authored 2026-07-18; `git diff --check` clean. |
| | M1.2 | Remove debian12 and rocky9: image dirs, workflows, configure image lists | ✅ | | ← G1 | 2026-07-18: dirs, workflows, and configure lists removed; stale `.bak`/`.un~` backups swept; `make check` passes with debian13/mdbook/rocky8/rocky10. |
| | M1.3 | Purge stale references (README, release.bash target list) | ✅ | | ← M1.2 | 2026-07-18: README image table, `release.bash` workflow list, ARCHITECTURE.md rows updated; the completed 2025 refactor plan doc removed per owner decision (preserved at tag 1.2.0); OS-token grep clean. Correction (rs20260718_025216 F001): the top-level README doc-index row referencing the removed plan survived that grep; fixed in this session. |
| M2 Distribution images | M2.1 | Rewrite debian13 Dockerfile: consume `EPICS-env-distribution` `1.2.1/debian-13/7.0.10` (ARG-pinned version); OS package layer separate; sparse fetch (`--depth 1 --filter=blob:none` + sparse-checkout of the one OS tree) with `.git` removed in the same RUN; bake manifest | ⬜ | ▶ | ← M1.2 · ← D2 · ← D3 | Image builds; `docker run` without sourcing shows `EPICS_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH=linux-x86_64`; `PATH` carries base+pvxs+pmac bin dirs; `LD_LIBRARY_PATH` carries base lib only (modules resolve via RUNPATH); consumer build toolchain present; measured image size recorded. |
| | M2.2 | Apply the pattern to rocky 8.10 | ⬜ | | ← M2.1 | Same verification as M2.1. |
| | M2.3 | Apply the pattern to rocky 10.x (latest) | ⬜ | | ← M2.1 | Same verification as M2.1. |
| | M2.4 | Derive and pin the minimal per-OS runtime package set (pvxs links system libevent) | ⬜ | | ← M2.1 | NEEDED set derived in-image (`readelf`/`ldd` over base bin + modules); per-OS package list pinned in the Dockerfiles; lists are needs-verification until executed in-image. |
| M3 IOC runtime layer | M3.1 | Build procServ and con in the final stage with the resident toolchain (ansible-provision role recipes; sources removed in the same RUN) | ⬜ | | ← M2.1 · ← M2.2 · ← M2.3 | Both executables present and runnable in all three images. |
| | M3.2 | Include the `tools` IOC generator | ⬜ | | ← M3.1 | Inside a container: generate an IOC, build it, start it. |
| | M3.3 | Reintroduce ioc-runner (container execution mode) | 🔒 | | ← M3.1 · ← G3 | ioc-runner start/stop works in a systemd-less container. |
| M4 Verification gates | M4.1 | Container gate script: softIoc start, record registration, CA data path, PVA execution probe, module inventory count (64 at 1.2.1), dead-symlink scan, vendored `check_deps.bash` (explicit tree path; binutils present; RPATH hygiene only) | ⬜ | | ← M2.1 · ← M2.2 · ← M2.3 | All gates pass on all three images. |
| | M4.2 | Wire the gates into CI per image build | ⬜ | | ← M4.1 · ← M5.2 | Every PR and push build loads the image, runs the gates, and pushes only after the gates pass on that same build. |
| M5 CI and publish | M5.1 | Settle the image name/tag scheme (`latest` tracks newest; version tags follow the distribution version) | 🔄 | | | Scheme settled and recorded as D10 (2026-07-18); remaining: env.conf and workflow tag expressions made consistent, which lands with M5.2's dual-tag plumbing. |
| | M5.2 | Update GitHub Actions for the 3-OS build (shape per morning decision D-2): dual-tag plumbing (build-push `tags` list or metadata outputs; `release.bash` rework-or-retire; `docker_builder.bash`/env.conf tag extension or recorded latest-only), `concurrency` group, trigger mechanism kept or replaced explicitly | ⬜ | | ← M2.1 · ← M2.2 · ← M2.3 · ← M5.1 | CI green, evidenced via a PR to master (workflows do not fire from `legacy-trim` pushes). |
| | M5.3 | Publish to Docker Hub | 🔒 | | ← G2 | Tags visible on Docker Hub per the M5.1 scheme. |
| M6 Documentation | M6.1 | Documentation overhaul per D14: keep only needed documents, create new ones where warranted, retire obsolete ones (README, ARCHITECTURE.md, SUPPORT.md in scope) | ⬜ | | ← M2.1 · ← M3.1 · ← M5.2 | Non-ASCII markdown check and `git diff --check` pass; every remaining document matches the shipped structure; retired documents are recorded in the removing commit. |
| M7 Deferred | M7.1 | mdbook image modernization | ⬜ | | | Image builds with the latest pinned mdbook and renders a site through the GitLab Pages template flow (scheduled independently, outside this cycle). |
| | M7.2 | Image vulnerability scanning (report-only) | ⬜ | | | Backlogged per D15; done-when defined when picked up. |

## External gates (G)

| G | What | Blocks | Status | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| G1 | Legacy closing tag on master (owner-run) | M1.2 | Satisfied 2026-07-18 | Annotated tag `1.2.0` ("Close the legacy image line") on master, pushed to origin. |
| G2 | Docker Hub publish authorization and execution | M5.3 | Open | Owner-run push. |
| G3 | epics-ioc-runner container execution mode | M3.3 | Open | jeonghanlee/epics-ioc-runner#127 (Backlog, filed 2026-07-18). |
| G4 | GitLab consumer cutover — coordinated template change + runner-image rollout per D13 | M2-image rollout to runners | Open | Strategy decided (D13, no stub); `rocky10-epics.yml` builder-only template authored in the ci repository (uncommitted); cutover sequencing planned after M2 images exist. |

## Decisions (D)

| D | Content | Decided in |
| :-- | :-- | :-- |
| D1 | Targets are debian13, rocky 8.10, rocky 10.x (latest); images carry the EPICS environment only | 2026-07-18 |
| D2 | Consume prebuilt `EPICS-env-distribution` binaries; no EPICS-environment compilation during image build. The consumer build toolchain ships in the final image — runner jobs compile IOCs in-container. Vendor libraries (uldaq, open62541) arrive inside the distribution `vendor/` tree; no separate build layers (rs20260718_025216 F007; ratified 2026-07-18) | 2026-07-18 |
| D3 | Remove `setEnv`; bake the environment via Dockerfile `ENV` — full list enumerated in M2.1: `EPICS_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH`, `PATH` (base+pvxs+pmac bins), `LD_LIBRARY_PATH` (base lib only) (rs20260718_025216 F003; ratified 2026-07-18) | 2026-07-18 |
| D4 | Exclude ioc-runner until its container mode exists (#127); procServ direct execution covers container IOC use meanwhile | 2026-07-18 |
| D5 | Exclude analyzer tools; GitLab tester jobs are removed on the `alsu/ci` side | 2026-07-18 |
| D6 | `latest` tag tracks the newest image; version tags follow the distribution version | 2026-07-18 |
| D7 | Legacy CI failures (mo-rfdist PIE, zpsc RELEASE wiring, stale template refs) are consumer-project defects, tracked in the `alliocs` register (its M5 group); no legacy image fix needed here | 2026-07-18 |
| D8 | Docker Hub publish blocked at the workflow level (`push: false` in all three image workflows) until M5.2 lands the gated load-gate-push shape; resolves session decision D-1 | 2026-07-18 |
| D9 | M5.2 workflow shape: one reusable `workflow_call` workflow plus three thin per-OS callers preserving the current path filters and `.trigger` rebuild channel (session D-2) | 2026-07-18 |
| D10 | Tag scheme: image names stay `<os>-epics` (GitLab consumer contract); version tags follow the `EPICS-env-distribution` release (e.g. `debian13-epics:1.2.1`); `latest` tracks the newest; EPICS base version recorded in image labels (session D-3) | 2026-07-18 |
| D11 | `RELEASE.md` removed — release history lives in GitHub Releases only (session D-4) | 2026-07-18 |
| D12 | rocky10 base pinned to `rockylinux:10.2`, matching the distribution build OS; new minors are followed promptly with a distribution rebuild — the rocky10 line exists to catch next-stable problems early (session D-5) | 2026-07-18 |
| D13 | GitLab consumer cutover is coordinated (no transition stub): `alsu/ci` template change and runner-image rollout land together under G4; `rocky10-epics.yml` (builder-only) authored in the ci repository (session D-6) | 2026-07-18 |
| D14 | M6 is a full documentation overhaul: keep only needed documents, create new ones where warranted, retire obsolete ones — README, ARCHITECTURE.md, SUPPORT.md all in scope (session D-7) | 2026-07-18 |
| D15 | Image vulnerability scanning deferred to the backlog (M7.2) — base-OS findings are not actionable here (session D-8) | 2026-07-18 |

## Conventions

- The register is written in English; status markers use the emoji set above,
  matching the `alliocs` register format.
- One task row is one deliverable + verification pair.
- `Progress` = done/total tasks in the group; the group `Status` and ready set
  derive from the tasks and their dependency arrows, not hand-written.
