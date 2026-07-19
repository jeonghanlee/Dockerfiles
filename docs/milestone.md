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
Done 2026-07-18:   M1 complete · G1 · session rs20260718_025216 CLOSED (decisions D8-D18)
                   · M2 COMPLETE (4/4): three images built, verified, pruned (912/891/944MB)
Done 2026-07-19:   M3.1 (procServ+con) · tools -> M7.4 · M4.1 (gate.bash 11/11, 3 reviewers)
                   · M5.1 (tag scheme applied) · M5.2/M4.2 authored (reusable image.yml +
                     gate-before-publish; release.bash retired; dist-version/versions helpers)

Next entry points:
  ▶ ready now:   M6.1 (documentation overhaul — README/ARCHITECTURE/SUPPORT)
  planned order: M6.1 → then master PR-run verifies M5.2/M4.2 CI-green → [G2] M5.3
  external wait: M5.2/M4.2 CI-green ← the master PR-run (deferred to merge-prep) ; M3.3 ← G3

External wait:  M5.3 ← G2 (Docker Hub publish) · M3.3 ← G3 (epics-ioc-runner#127) · M2 rollout ← G4 (consumer cutover, D13)
Operator action:  none standing (G2 arrives at M5.3; G4 sequencing planned after M2)

Next session entry point: M2.4 — prune pure-surplus packages (candidate cuts
opencv, unused X11/motif dev headers) from all three images, confirming each cut
is unused via in-image readelf NEEDED, then rebuild through the deep gate.
```

Tally: 19 tasks — ✅ 10 · 🔄 2 · ⬜ 5 · 🔒 2 / ready(▶) 1 · external gates 4 (G1 satisfied · G2·G3·G4 open)

## Groups (L1)

| Group | Name | Progress | Status | Next |
| :-- | :-- | :-- | :-- | :-- |
| M1 | Legacy trim (#26) | 3/3 | ✅ | |
| M2 | Distribution-based images (#27) | 4/4 | ✅ | |
| M3 | IOC runtime layer (#28) | 1/2 | 🔄 | (M3.3 blocked; tools deferred to M7.4) |
| M4 | Verification gates (#29) | 1/2 | 🔄 | (M4.2 authored; CI-green pending PR) |
| M5 | CI and publish (#30) | 1/3 | 🔄 | (M5.2 authored; CI-green pending PR) |
| M6 | Documentation (#31) | 0/1 | ⬜ | ▶ M6.1 |
| M7 | Deferred follow-ups (#32) | 0/4 | ⬜ | |

## Tasks (L2)

The `Group` cell is written once per group (continuation rows are blank).

| Group | ID | Task | Status | Next | Deps | Done when / Evidence |
| :-- | :-- | :-- | :-- | :-: | :-- | :-- |
| M1 Legacy trim | M1.1 | Author this register on `legacy-trim` | ✅ | | | Register authored 2026-07-18; `git diff --check` clean. |
| | M1.2 | Remove debian12 and rocky9: image dirs, workflows, configure image lists | ✅ | | ← G1 | 2026-07-18: dirs, workflows, and configure lists removed; stale `.bak`/`.un~` backups swept; `make check` passes with debian13/mdbook/rocky8/rocky10. |
| | M1.3 | Purge stale references (README, release.bash target list) | ✅ | | ← M1.2 | 2026-07-18: README image table, `release.bash` workflow list, ARCHITECTURE.md rows updated; the completed 2025 refactor plan doc removed per owner decision (preserved at tag 1.2.0); OS-token grep clean. Correction (rs20260718_025216 F001): the top-level README doc-index row referencing the removed plan survived that grep; fixed in this session. |
| M2 Distribution images | M2.1 | Rewrite debian13 Dockerfile: consume `EPICS-env-distribution` `1.2.1/debian-13/7.0.10` (ARG-pinned version); OS package layer separate; sparse fetch (`--depth 1 --filter=blob:none` + sparse-checkout of the one OS tree) with `.git` removed in the same RUN; bake manifest | ✅ | | ← M1.2 · ← D2 · ← D3 | 2026-07-18: built and verified — all baked variables present without sourcing; PATH = pmac+pvxs+base bins; LD_LIBRARY_PATH = base lib only; gcc/make/perl/python resolve; manifest records distribution commit e2c1b4e; module inventory 64/64; size 1.21GB (legacy rocky9 was 2.2GB). Smoke beyond done-when: `pvxinfo -V` loads (system libevent OK), softIoc registers a calc record. Deep gate (definitive, container-native): 35/35 cloned, 30 green, 5 fails all external — converges with rocky8/rocky10 exactly. Per-OS sweep found and fixed an image gap: `openssh-client` was absent (git-over-ssh impossible); now explicit in all three package layers. |
| | M2.2 | Apply the pattern to rocky 8.10 | ✅ | | ← M2.1 | 2026-07-18: built first-try; env baked, tools resolve, 64/64 modules, pvxinfo loads (el8 system libevent), record registers; 1.11GB. Deep gate (definitive, container-native): 35/35 cloned, 30 green, 5 fails all external (4 site-module + nsls2 bpc-ioc) — matches rocky10 exactly. |
| | M2.3 | Apply the pattern to rocky 10.x (10.2 pinned per D12) | ✅ | | ← M2.1 | 2026-07-18: built first-try on `rockylinux:10.2` (os-release 10.2 confirmed); el10 package renames applied (crb, pcre2-devel, libusb1-devel, python3 default); same verification battery green; 1.31GB. Deep gate (definitive, container-native with seeded known_hosts): 35/35 cloned, 30 green on the el10 toolchain — zero image-attributable failures. Fails: 4 site-module IOCs (llrf/mks937b/rga/vac-plc, D17) + alsu/nsls2 `bpc-ioc` (new-line repo defect, alliocs M4 territory). Earlier 23/24 counts were host-tree snapshot subsets, not build differences. |
| | M2.4 | Prune pure surplus from the dev-carrying images (D18 option 1) | ✅ | | ← M2.1 · ← D18 | 2026-07-18: 10-lane dependency review (rs20260718_192908) — cut X11/Motif (Xt/Xmu/Xpm/motif), netcdf/tiff/png, boost, plus per-OS libbz2/hidapi (debian), `pcre-devel` PCRE1 family (rocky8) / `pcre2-devel` (rocky10), libcurl, legacy libusb-0.1 (rocky); GUI extensions confirmed out of scope (owner). All cuts have zero linkage, zero module-header reference, zero consumer-IOC-build reference. Verified per image: `ldd` over base+modules clean (no "not found"), softIoc/pvxs smoke green, deep gate unchanged 30/35. Size: debian13 1.22->0.91GB, rocky8 1.11->0.89GB, rocky10 1.31->0.94GB. Residue deferred to M7.3: runtime-vs-dev downgrades, flex/ncurses-devel (disputed), and `pcre2-devel` on rocky8 (unavoidable transitive dep of `libselinux-devel`; `--whatrequires` by name empty, pulled by pcre2 capability). |
| M3 IOC runtime layer | M3.1 | Build procServ and con in the final stage with the resident toolchain (ansible-provision role recipes; sources removed in the same RUN) | ✅ | | ← M2.1 · ← M2.2 · ← M2.3 | 2026-07-19: both built in one RUN with a transient autotools set (autoconf/automake/libtool) installed and removed in-layer; procServ 2.9.0-dev + con present in all three images, commits recorded in the bake manifest. Runnable proof beyond --version: procServ launches a softIoc that stays alive. autotools removal verified not to touch the consumer toolchain (gcc/make/perl intact) — deep gate unchanged 30/35 on all three. Size: debian13 912->914MB, rocky8 891->931MB, rocky10 944->970MB. |
| | M3.3 | Reintroduce ioc-runner (container execution mode) | 🔒 | | ← M3.1 · ← G3 | ioc-runner start/stop works in a systemd-less container. |
| M4 Verification gates | M4.1 | Container gate script `gate.bash` + `make gate[.<image>]` target | ✅ | | ← M2.1 · ← M2.2 · ← M2.3 | 2026-07-19: `gate.bash` (11 gates G0-G10: env-baked, inventory 64, dead-symlink, pairing, module artifacts, softIoc+record, CA data path, PVA data path via softIocPVA+pvxget, relocatable linkage, IOC tools, bake manifest) runs in a built image; `make gate` covers RELEASE_IMAGE_DIRS (mdbook excluded), gate.bash added to check-scripts. 3-reviewer session rs20260719_005012 caught a blocking G8 false-pass (accepted empty/missing runpath) and its rocky false-fail; G8 rewritten to require a non-empty $ORIGIN-relative runpath (accepts DT_RPATH and DT_RUNPATH), G7 upgraded from pvxinfo to a real PVA round-trip, pairing gate added. Result: 11/11 on debian13/rocky8/rocky10 (run in default bridge net — host net breaks localhost CA/PVA). |
| | M4.2 | Wire the gates into CI per image build | 🔄 | | ← M4.1 · ← M5.2 | 2026-07-19: implemented inside the reusable `image.yml` (M5.2) — build+`load` then `docker run` the loaded image against `gate.bash`; publish only runs after the gate step. PENDING the same PR-to-master CI-green run as M5.2. |
| M5 CI and publish | M5.1 | Settle the image name/tag scheme (`latest` tracks newest; version tags follow the distribution version) | ✅ | | | Settled as D10 (2026-07-18) and applied 2026-07-19: tags derive from the Dockerfile `DIST_VERSION` ARG (single source); version management is `make dist-version.<v>` (bump all three) + `make versions` (show), replacing the retired `release.bash` (D21). |
| | M5.2 | Reworked GitHub Actions: reusable `image.yml` + 3 thin callers | 🔄 | | ← M2.1 · ← M2.2 · ← M2.3 · ← M5.1 | 2026-07-19 authored + locally validated (yamllint + `make check` clean): reusable `workflow_call` (D9) does build+`load` -> run `gate.bash` (M4.2) -> publish `latest`+`<DIST_VERSION>` (D10) only on a manual `workflow_dispatch` on master after the gate (D8; no auto-publish on merge). `release.bash` retired. Concurrency group + `gate.bash`/`image.yml` path filters added. PENDING: CI-green verification via a PR to master (deferred to merge-prep per owner). |
| | M5.3 | Publish to Docker Hub | 🔒 | | ← G2 | Tags visible on Docker Hub per the M5.1 scheme. |
| M6 Documentation | M6.1 | Documentation overhaul per D14: keep only needed documents, create new ones where warranted, retire obsolete ones (README, ARCHITECTURE.md, SUPPORT.md in scope) | ⬜ | ▶ | ← M2.1 · ← M3.1 · ← M5.2 | Non-ASCII markdown check and `git diff --check` pass; every remaining document matches the shipped structure; retired documents are recorded in the removing commit. |
| M7 Deferred | M7.1 | mdbook image modernization | ⬜ | | | Image builds with the latest pinned mdbook and renders a site through the GitLab Pages template flow (scheduled independently, outside this cycle). |
| | M7.2 | Image vulnerability scanning (report-only) | ⬜ | | | Backlogged per D15; done-when defined when picked up. |
| | M7.3 | Runtime-only slim image variant (D18 option 2): no compiler/`-devel`, minimal NEEDED set only, separate tag; for pure IOC execution (softIoc/runtime), not runner builds | ⬜ | | | Backlogged per D18; done-when defined when picked up. |
| | M7.4 | Include the `tools` IOC generator in the images | ⬜ | | | Deferred from M3 by owner 2026-07-19 ("툴은 일단 빼자"); done-when = inside a container generate an IOC, build it, start it. |

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
| D16 | In-image install root is `/opt/epics/<dist-version>/<os-dir>/<epics-version>` — the distribution tree shape preserved under `/opt/epics`, version visible in the path | 2026-07-18 |
| D17 | Consumer-compile deep gate = alliocs harness run in-container with the exclusion set recorded as alliocs M4.5 (2 GitHub regressions + 5 credential-gated clones). Site-module IOCs (llrf, mks937b, rga, vac-plc) are outside public-image scope: llrf resolves at distribution 1.3.0 (feed goes public — bump the `DIST_VERSION` ARG); the other three stay site-scoped | 2026-07-18 |
| D18 | Package footprint split in two designs: (1) prune only pure surplus while keeping the runner dev toolchain — priority, this cycle as M2.4; (2) a separate runtime-only slim image with no toolchain for pure execution — backlog as M7.3 | 2026-07-18 |
| D19 | The `tools` IOC generator is deferred out of this cycle's M3 and held in the backlog (M7.4); owner "툴은 일단 빼자" | 2026-07-19 |
| D20 | Observed via M4.1 gate (rs20260719_005012): rocky8/rocky10 `EPICS-env-distribution` binaries emit DT_RPATH (still `$ORIGIN`-relative, so relocatable) while debian uses DT_RUNPATH — a rocky-toolchain default (missing `-Wl,--enable-new-dtags`). Functionally fine; an upstream distribution-build fix, out of this repo's scope; surfaced to the owner. G8 accepts both tags. | 2026-07-19 |
| D21 | Version management: `release.bash` retired (its workflow-tag-sed model is dead). The image content version is the Dockerfile `DIST_VERSION` ARG (single source, read by CI for tags); `make dist-version.<v>` bumps all EPICS images at once; `make versions` shows per-image versions + repo git. Repo releases stay on git tags + GitHub Releases | 2026-07-19 |

## Conventions

- The register is written in English; status markers use the emoji set above,
  matching the `alliocs` register format.
- One task row is one deliverable + verification pair.
- `Progress` = done/total tasks in the group; the group `Status` and ready set
  derive from the tasks and their dependency arrows, not hand-written.
