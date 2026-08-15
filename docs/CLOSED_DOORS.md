# Closed Doors

Candidates that were examined and deliberately left unchanged. They are not
work items and never become milestone rows. Each entry records the verdict, the
premise behind it, the evidence, and when it was decided, so a later review can
close the same door in seconds instead of re-opening the investigation.

Open work lives in the canonical Work Register, not here.

## `pcre2-devel` stays in the rocky8 image

Status: Keep (examined, no action)
Decided: 2026-07-18
Evidence carried by: commit 5c186b4

Premise: the package prune removed the PCRE1 family from rocky8, and
`pcre2-devel` looked like the same kind of surplus. It is not removable in
isolation. A `dnf repoquery --whatrequires pcre2-devel` by name returns nothing,
but the package is pulled in as a capability dependency of `libselinux-devel`,
which the image needs. Removing it would take `libselinux-devel` with it.

Verdict: leave it installed. Its presence is a transitive consequence of a
required package, not surplus that survived the review. A future runtime-only
image without the dev toolchain would not carry it at all, which is where the
question properly belongs.

## `systemd-devel` stays in all three images

Status: Keep (examined, no action)
Decided: 2026-08-14
Evidence carried by: this commit

Premise: the package prune never examined `systemd-devel`, so it was an open
question rather than a settled one. Two observations were taken.

Nothing in the shipped EPICS tree links `libsystemd`. Scanning every shared
object and executable in the 1.2.2 distribution trees found zero references in
both `rocky-8.10/7.0.10` and `debian-13/7.0.10` (274 files each), while the
control term `libevent` was found 19 and 12 times respectively, so the scan was
reading what it claimed to read.

No IOC currently tracked at this site uses it either. Sweeping the 40 IOC
directories present in the `alliocs` working tree at `/data/gitsrc/alliocs`
found 6 matches for the systemd family, all unrelated: 4 are word fragments
inside APC PDU SNMP MIB object names, and 2 are host-level network tuning
notes. The control term `asyn` matched 4924 times in the same sweep, which is
what shows the sweep was reading IOC sources rather than silently skipping
them. Note that the count is of directories on disk, which exceeds the repos
listed in that repository's `IOC_REPOS` manifest; the sweep covered what was
present, not what the manifest declares.

Limit of that evidence: those 40 IOCs are the set this site tracks today, not
the set of everyone who builds against these images. The images exist to
compile consumer IOCs whose contents are not known in advance, so an absence
observed in one site's current tree cannot establish that no future or
off-site consumer needs the headers.

Verdict: leave it installed. The saving is one development header package,
while removing it would silently break any consumer that does need systemd
headers, and no evidence available here can rule that out. Revisit only if the
image is redefined so that its consumers are a known, closed set - which is
what a runtime-only image without a toolchain would be.

## The gate accepts both `DT_RPATH` and `DT_RUNPATH`

Status: Keep (examined, no action)
Decided: 2026-07-19, re-observed 2026-08-14
Evidence carried by: this commit

Premise: the container gate checks that shipped binaries carry a non-empty
`$ORIGIN`-relative runpath so the tree stays relocatable. At distribution
1.2.1 the rocky binaries were observed emitting `DT_RPATH` while debian emitted
`DT_RUNPATH`, attributed to the rocky toolchain not defaulting to
`-Wl,--enable-new-dtags`. The gate was briefly suspected of failing rocky for
that reason, and was written to accept either tag.

Re-observed at 1.2.2 on 2026-08-14: all three images now emit `DT_RUNPATH`
only. Scanning the shared objects under `/opt/epics` with `readelf -d` found
16 `RUNPATH` and zero `RPATH` in each of debian13, rocky8, and rocky10. Why the
rocky output changed between 1.2.1 and 1.2.2 is not known here; the linker
flags belong to the upstream `EPICS-env-distribution` build, not to this
repository.

Verdict: nothing to change. The distinction never affected relocation, since
both tags are `$ORIGIN`-relative, and the gate accepts either - which is why
the change in upstream behaviour passed unnoticed and cost nothing. Keep the
gate tolerant of both rather than narrowing it to whatever the current
toolchain happens to emit.
