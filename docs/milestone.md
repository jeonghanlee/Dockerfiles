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
In progress (🔄):  none
Done 2026-07-18:   M1 complete (register · trim · reference purge) · G1 (tag 1.2.0 pushed)
                   · review session rs20260718_025216 converged (3 lanes, F001-F008 applied)

Next entry points:
  ▶ ready now:   morning decision packet D-1..D-8 (session convergence report, Open section)
                 then M2.1 (debian13 Dockerfile rewrite) · M5.1 (name/tag scheme = D-3)
  planned order: M2.1 → M2.2 · M2.3 → M2.4 → M3.1 · M3.2 → M4.1 → M5.2 → M4.2 → [G2] M5.3 → M6.1

External wait:  M5.3 ← G2 (Docker Hub publish) · M3.3 ← G3 (epics-ioc-runner#127) · M2 rollout ← G4 (consumer cutover)
Operator action:  morning owner session — decide D-1..D-8; ratify D2/D3 rewording

Next session entry point: morning owner review of
`work/review_sessions/rs20260718_025216_milestone-review/convergence/` (decision
packet D-1..D-8), then start M2.1 per its enriched task row.
```

Tally: 17 tasks — ✅ 3 · 🔄 0 · ⬜ 12 · 🔒 2 / ready(▶) 2 · external gates 4 (G1 satisfied · G2·G3·G4 open)

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
| M5 CI and publish | M5.1 | Settle the image name/tag scheme (`latest` tracks newest; version tags follow the distribution version) | ⬜ | ▶ | | Recorded as a Decision row; env.conf and workflow tag expressions consistent with it. |
| | M5.2 | Update GitHub Actions for the 3-OS build (shape per morning decision D-2): dual-tag plumbing (build-push `tags` list or metadata outputs; `release.bash` rework-or-retire; `docker_builder.bash`/env.conf tag extension or recorded latest-only), `concurrency` group, trigger mechanism kept or replaced explicitly | ⬜ | | ← M2.1 · ← M2.2 · ← M2.3 · ← M5.1 | CI green, evidenced via a PR to master (workflows do not fire from `legacy-trim` pushes). |
| | M5.3 | Publish to Docker Hub | 🔒 | | ← G2 | Tags visible on Docker Hub per the M5.1 scheme. |
| M6 Documentation | M6.1 | Rewrite README system-centric (architecture, function, data flow) | ⬜ | | ← M2.1 · ← M3.1 · ← M5.2 | Non-ASCII markdown check and `git diff --check` pass; content matches the shipped structure. |
| M7 Deferred | M7.1 | mdbook image modernization | ⬜ | | | Image builds with the latest pinned mdbook and renders a site through the GitLab Pages template flow (scheduled independently, outside this cycle). |

## External gates (G)

| G | What | Blocks | Status | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| G1 | Legacy closing tag on master (owner-run) | M1.2 | Satisfied 2026-07-18 | Annotated tag `1.2.0` ("Close the legacy image line") on master, pushed to origin. |
| G2 | Docker Hub publish authorization and execution | M5.3 | Open | Owner-run push. |
| G3 | epics-ioc-runner container execution mode | M3.3 | Open | jeonghanlee/epics-ioc-runner#127 (Backlog, filed 2026-07-18). |
| G4 | GitLab consumer cutover — `alsu/ci` templates still `source setEnv`; runner-tag rollout coordination; rocky10 consumer template absent | M2-image rollout to runners | Open | Strategy is morning decision D-6 (rs20260718_025216 F008/F014). |

## Decisions (D)

| D | Content | Decided in |
| :-- | :-- | :-- |
| D1 | Targets are debian13, rocky 8.10, rocky 10.x (latest); images carry the EPICS environment only | 2026-07-18 |
| D2 | Consume prebuilt `EPICS-env-distribution` binaries; no EPICS-environment compilation during image build. The consumer build toolchain ships in the final image — runner jobs compile IOCs in-container (rs20260718_025216 F007; ratify 2026-07-18 AM) | 2026-07-18 |
| D3 | Remove `setEnv`; bake the environment via Dockerfile `ENV` — full list enumerated in M2.1: `EPICS_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH`, `PATH` (base+pvxs+pmac bins), `LD_LIBRARY_PATH` (base lib only) (rs20260718_025216 F003; ratify 2026-07-18 AM) | 2026-07-18 |
| D4 | Exclude ioc-runner until its container mode exists (#127); procServ direct execution covers container IOC use meanwhile | 2026-07-18 |
| D5 | Exclude analyzer tools; GitLab tester jobs are removed on the `alsu/ci` side | 2026-07-18 |
| D6 | `latest` tag tracks the newest image; version tags follow the distribution version | 2026-07-18 |
| D7 | Legacy CI failures (mo-rfdist PIE, zpsc RELEASE wiring, stale template refs) are consumer-project defects, tracked in the `alliocs` register (its M5 group); no legacy image fix needed here | 2026-07-18 |

## Conventions

- The register is written in English; status markers use the emoji set above,
  matching the `alliocs` register format.
- One task row is one deliverable + verification pair.
- `Progress` = done/total tasks in the group; the group `Status` and ready set
  derive from the tasks and their dependency arrows, not hand-written.
