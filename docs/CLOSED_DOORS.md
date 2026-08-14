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
directories in the `alliocs` repository found 6 matches for the systemd family,
all unrelated: 4 are word fragments inside APC PDU SNMP MIB object names, and 2
are host-level network tuning notes. The control term `asyn` matched 4924 times
in the same sweep.

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

## rocky8 and rocky10 binaries emit `DT_RPATH` rather than `DT_RUNPATH`

Status: Keep (examined, no action)
Decided: 2026-07-19
Evidence carried by: commit 5c186b4

Premise: the container gate checks that shipped binaries carry a non-empty
`$ORIGIN`-relative runpath so the tree stays relocatable. On debian the linker
emits `DT_RUNPATH`; on both rocky lines it emits `DT_RPATH`, because the rocky
toolchain does not default to `-Wl,--enable-new-dtags`. The gate was briefly
suspected of a false failure on rocky.

Verdict: functionally equivalent for this purpose. Both tags are
`$ORIGIN`-relative, so relocation works identically, and the gate accepts
either. The difference originates in how `EPICS-env-distribution` is built
upstream, not in these images, so there is nothing to change in this
repository. It was surfaced to the owner and left as is.
