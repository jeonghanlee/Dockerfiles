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
Done 2026-07-18:   M1.1 (this register authored on legacy-trim)

Next entry points:
  ▶ ready now:   M5.1 (image name/tag scheme — owner decision only)
  planned order: [G1] → M1.2 → M1.3 → M2.1 → M2.2 · M2.3 → M3.1 · M3.2 → M4.1 → M5.2 → M4.2 → [G2] M5.3 → M6.1

External wait:  M1.2 ← G1 (legacy closing tag) · M5.3 ← G2 (Docker Hub publish) · M3.3 ← G3 (epics-ioc-runner#127)
Operator action:  G1 tag on master (version choice open; existing: 1.0.0, v1.0.0, v1.1.0) · M5.1 scheme confirmation

Next session entry point: after G1, start M1.2 — remove the debian12 and rocky9
image directories, their workflows, and the configure image lists; verify with
`make check` showing only debian13/rocky8/rocky10/mdbook remaining.
```

Tally: 16 tasks — ✅ 1 · 🔄 0 · ⬜ 12 · 🔒 3 / ready(▶) 1 · external gates 3 (G1·G2·G3 open)

## Groups (L1)

| Group | Name | Progress | Status | Next |
| :-- | :-- | :-- | :-- | :-- |
| M1 | Legacy trim (#26) | 1/3 | 🔄 | |
| M2 | Distribution-based images (#27) | 0/3 | ⬜ | |
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
| | M1.2 | Remove debian12 and rocky9: image dirs, workflows, configure image lists | 🔒 | | ← G1 | `make check` passes with only debian13/rocky8/rocky10/mdbook in `IMAGE_DIRS`. |
| | M1.3 | Purge stale references (README, release.bash target list) | ⬜ | | ← M1.2 | Repository-wide grep finds no debian12/rocky9 references. |
| M2 Distribution images | M2.1 | Rewrite debian13 Dockerfile: sparse-checkout distribution OS tree, single fetch-place-clean RUN, ENV-baked environment, bake manifest | ⬜ | | ← M1.2, D2, D3 | Image builds; `docker run` shows `EPICS_BASE`/`EPICS_HOST_ARCH`/`PATH`/`LD_LIBRARY_PATH` set without sourcing anything. |
| | M2.2 | Apply the pattern to rocky 8.10 | ⬜ | | ← M2.1 | Same verification as M2.1. |
| | M2.3 | Apply the pattern to rocky 10.x (latest) | ⬜ | | ← M2.1 | Same verification as M2.1. |
| M3 IOC runtime layer | M3.1 | Add procServ and con build layers (ansible-provision role recipes; sources removed after install) | ⬜ | | ← M2.1 | Both executables present and runnable in all three images. |
| | M3.2 | Include the `tools` IOC generator | ⬜ | | ← M3.1 | Inside a container: generate an IOC, build it, start it. |
| | M3.3 | Reintroduce ioc-runner (container execution mode) | 🔒 | | ← G3 | ioc-runner start/stop works in a systemd-less container. |
| M4 Verification gates | M4.1 | Container gate script: softIoc start, record registration, CA data path, check_deps | ⬜ | | ← M2.1 | All gates pass on all three images. |
| | M4.2 | Wire the gates into CI per image build | ⬜ | | ← M4.1, M5.2 | Every PR build runs the gates automatically. |
| M5 CI and publish | M5.1 | Settle the image name/tag scheme (`latest` tracks newest; version tags follow the distribution version) | ⬜ | ▶ | | Recorded as a Decision row; env.conf and workflow tag expressions consistent with it. |
| | M5.2 | Update GitHub Actions to the 3-OS matrix | ⬜ | | ← M2.1, ← M2.2, ← M2.3, ← M5.1 | CI green on the branch. |
| | M5.3 | Publish to Docker Hub | 🔒 | | ← G2 | Tags visible on Docker Hub per the M5.1 scheme. |
| M6 Documentation | M6.1 | Rewrite README system-centric (architecture, function, data flow) | ⬜ | | ← M2.1, ← M3.1, ← M5.2 | Non-ASCII markdown check and `git diff --check` pass; content matches the shipped structure. |
| M7 Deferred | M7.1 | mdbook image modernization | ⬜ | | | Started as its own task outside this cycle. |

## External gates (G)

| G | What | Blocks | Status | Evidence |
| :-- | :-- | :-- | :-- | :-- |
| G1 | Legacy closing tag on master (owner-run; version choice open) | M1.2 | Open | Existing tags: 1.0.0, v1.0.0, v1.1.0. |
| G2 | Docker Hub publish authorization and execution | M5.3 | Open | Owner-run push. |
| G3 | epics-ioc-runner container execution mode | M3.3 | Open | jeonghanlee/epics-ioc-runner#127 (Backlog, filed 2026-07-18). |

## Decisions (D)

| D | Content | Decided in |
| :-- | :-- | :-- |
| D1 | Targets are debian13, rocky 8.10, rocky 10.x (latest); images carry the EPICS environment only | 2026-07-18 |
| D2 | Consume prebuilt `EPICS-env-distribution` binaries; no in-image compilation | 2026-07-18 |
| D3 | Remove `setEnv`; bake `PATH`, `LD_LIBRARY_PATH`, `EPICS_BASE`, `EPICS_MODULES`, `EPICS_HOST_ARCH` via Dockerfile `ENV` | 2026-07-18 |
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
