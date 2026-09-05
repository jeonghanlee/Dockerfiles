#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.3.0
#
# Container verification gate. Runs INSIDE a built image and
# checks the installed EPICS tree and runtime tools. Distinct from the repo's
# build-time `make check`: this validates a produced image, not the sources.
#
# Usage (from the `make gate.<image>` target or by hand):
#   docker run --rm -v "$PWD/gate.bash:/gate.bash:ro" <image> bash /gate.bash
#
# Each gate prints PASS/FAIL on one line; the script runs every gate and exits
# non-zero if any failed, so one run reports the full picture.

set -uo pipefail

declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0

# Expected shared-module entry count for the pinned distribution. The modules
# directory holds 64 entries (symlink + version-dir pairs); this counts
# entries, not module identities (name/version identity is the distribution's
# manifest concern, out of this gate's scope).
declare EXPECTED_MODULES="${GATE_EXPECTED_MODULES:-64}"

function pass { printf "PASS  %s\n" "$1"; PASS_COUNT+=1; }
function fail { printf "FAIL  %s\n" "$1"; FAIL_COUNT+=1; }

# G0 - environment baked without sourcing. Hard precondition: if the baked
# environment is absent, the tree gates below cannot run meaningfully, so report
# and exit rather than let later gates misfire on unset paths.
function gate_env {
    local ok=1 v
    for v in EPICS_PATH EPICS_BASE EPICS_MODULES EPICS_HOST_ARCH; do
        [[ -n "${!v:-}" ]] || { fail "G0 env: ${v} unset"; ok=0; }
    done
    if (( ok )); then
        [[ -d "${EPICS_BASE}" ]]   || { fail "G0 env: EPICS_BASE is not a directory"; ok=0; }
        [[ -d "${EPICS_MODULES}" ]] || { fail "G0 env: EPICS_MODULES is not a directory"; ok=0; }
        [[ ":${PATH}:" == *":${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:"* ]] || { fail "G0 env: base bin not on PATH"; ok=0; }
        [[ "${LD_LIBRARY_PATH:-}" == *"${EPICS_BASE}/lib/${EPICS_HOST_ARCH}"* ]] || { fail "G0 env: base lib not on LD_LIBRARY_PATH"; ok=0; }
    fi
    if (( ok )); then
        pass "G0 env baked (EPICS_PATH/BASE/MODULES/HOST_ARCH, PATH, LD_LIBRARY_PATH)"
    else
        printf -- "-- environment not baked; aborting before tree gates --\n" >&2
        exit 1
    fi
}

# G1 - module inventory count
function gate_inventory {
    local n
    n="$(find "${EPICS_MODULES}" -maxdepth 1 -mindepth 1 | wc -l)"
    if [[ "${n}" == "${EXPECTED_MODULES}" ]]; then
        pass "G1 module inventory ${n}/${EXPECTED_MODULES} entries"
    else
        fail "G1 module inventory ${n}, expected ${EXPECTED_MODULES}"
    fi
}

# G2 - no dead module symlinks
function gate_symlinks {
    local dead
    dead="$(find "${EPICS_MODULES}" -maxdepth 1 -xtype l)"
    if [[ -z "${dead}" ]]; then
        pass "G2 no dead module symlinks"
    else
        fail "G2 dead symlinks: ${dead}"
    fi
}

# G3 - module pairing: every top-level symlink resolves to a non-empty dir
function gate_pairing {
    local link target ok=1
    while IFS= read -r link; do
        target="$(readlink -f "${link}")"
        if [[ ! -d "${target}" ]]; then
            fail "G3 pairing: ${link##*/} target missing"; ok=0
        elif [[ -z "$(ls -A "${target}" 2>/dev/null)" ]]; then
            fail "G3 pairing: ${link##*/} target empty"; ok=0
        fi
    done < <(find "${EPICS_MODULES}" -maxdepth 1 -type l)
    (( ok )) && pass "G3 module pairing (every symlink resolves to a non-empty dir)"
}

# G4 - record-support modules ship dbd + headers
function gate_artifacts {
    local m ok=1
    for m in calc asyn busy sscan std; do
        if ! ls "${EPICS_MODULES}"/${m}-*/dbd/*.dbd >/dev/null 2>&1; then
            fail "G4 artifact ${m}: no dbd"; ok=0
        elif ! ls "${EPICS_MODULES}"/${m}-*/include/*.h >/dev/null 2>&1; then
            fail "G4 artifact ${m}: no include headers"; ok=0
        fi
    done
    (( ok )) && pass "G4 module artifacts (calc/asyn/busy/sscan/std dbd+include)"
}

# G5 - softIoc process + record registration
function gate_softioc {
    local db="/tmp/gate_smoke.db"
    printf 'record(calc,"gate:smoke"){field(CALC,"1+1")}\n' > "${db}"
    if printf 'dbl\nexit\n' | softIoc -d "${db}" 2>/dev/null | grep -q "gate:smoke"; then
        pass "G5 softIoc starts and registers a record"
    else
        fail "G5 softIoc did not register the record"
    fi
}

# G6 - Channel Access data path. The `sleep 25 |` keeps softIoc's stdin open so
# a backgrounded IOC does not read EOF and exit before caget runs.
function gate_ca {
    local db="/tmp/gate_smoke.db" pid
    printf 'record(calc,"gate:smoke"){field(CALC,"1+1")}\n' > "${db}"
    ( sleep 25 | softIoc -d "${db}" >/dev/null 2>&1 ) &
    pid=$!
    sleep 5
    if caget -t gate:smoke.CALC >/dev/null 2>&1; then
        pass "G6 Channel Access data path (caget)"
    else
        fail "G6 caget could not read the record"
    fi
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
}

# G7 - PVA data path: softIocPVA serves the record over pvAccess, pvxget reads it
function gate_pva {
    local db="/tmp/gate_pva.db" pid
    printf 'record(calc,"gate:pva"){field(CALC,"2+3")}\n' > "${db}"
    ( sleep 25 | softIocPVA -d "${db}" >/dev/null 2>&1 ) &
    pid=$!
    sleep 5
    if pvxget gate:pva >/dev/null 2>&1; then
        pass "G7 PVA data path (softIocPVA + pvxget)"
    else
        fail "G7 pvxget could not read over PVA"
    fi
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
}

# G8 - relocatable linkage. The invariant is a NON-EMPTY, $ORIGIN-relative
# runpath. Both DT_RUNPATH (debian toolchain) and DT_RPATH (rocky toolchain, no
# --enable-new-dtags) are accepted as long as every path component is $ORIGIN-
# relative; a missing tag, an empty path (the silent-empty-runpath trap), or any
# absolute component fails.
function gate_linkage {
    local f line paths comp ok=1
    local -a sample=(
        "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}/libdbCore.so"
        "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}/libCom.so"
        "${EPICS_BASE}/lib/${EPICS_HOST_ARCH}/libca.so"
    )
    local m
    for m in asyn calc seq StreamDevice pvxs; do
        sample+=( "${EPICS_MODULES}/${m}-"*"/lib/${EPICS_HOST_ARCH}/lib${m}.so" )
    done
    for f in "${sample[@]}"; do
        f="$(ls ${f} 2>/dev/null | head -n1)"
        [[ -n "${f}" && -e "${f}" ]] || continue
        line="$(readelf -d "${f}" 2>/dev/null | grep -E '\((RPATH|RUNPATH)\)')"
        if [[ -z "${line}" ]]; then
            fail "G8 linkage: ${f##*/} has no RPATH/RUNPATH"; ok=0; continue
        fi
        paths="$(printf '%s\n' "${line}" | sed -n 's/.*\[\(.*\)\].*/\1/p' | head -n1)"
        if [[ -z "${paths}" ]]; then
            fail "G8 linkage: ${f##*/} has an empty runpath"; ok=0; continue
        fi
        local IFS=:
        for comp in ${paths}; do
            [[ "${comp}" == "\$ORIGIN"* ]] || { fail "G8 linkage: ${f##*/} non-\$ORIGIN path: ${comp}"; ok=0; }
        done
    done
    (( ok )) && pass "G8 relocatable linkage (non-empty, \$ORIGIN-relative RPATH/RUNPATH)"
}

# G9 - IOC runtime tools present and runnable. The six s6 binaries are the
# ioc-runner container mode's entry points, the tools it calls directly; this
# check names a missing one precisely. Whether the suite actually works is not
# a question a binary list can answer (the tools exec others among themselves),
# so sufficiency is G11's job.
function gate_tools {
    local ok=1 b
    /usr/local/bin/procServ --version >/dev/null 2>&1 || { fail "G9 procServ not runnable"; ok=0; }
    [[ -x /usr/local/bin/con ]] || { fail "G9 con not present"; ok=0; }
    for b in s6-svscan s6-supervise s6-svc s6-svstat s6-svscanctl s6-setuidgid; do
        command -v "${b}" >/dev/null 2>&1 || { fail "G9 ${b} not on PATH"; ok=0; }
    done
    (( ok )) && pass "G9 IOC runtime tools (procServ, con, s6 entry points)"
}

# G11 - s6 supervision cycle. G9 only proves the runner can find what it
# calls; whether the suite runs depends on the s6 binaries those tools exec
# among themselves (s6-svc -w* execs s6-svlisten1, for one), and the full
# toolset ships precisely because that closure was never measured. So
# sufficiency is asserted by behaviour, not by a binary count: run a real
# supervision tree, drop a service to an unprivileged account, stop it with the
# wait options the runner uses, and tear the tree down. The options exercised
# (-wD -T, -o) are the ones that fix the runner's 2.13 version floor, so a
# sub-floor s6 fails here without a separate version check.
function gate_s6 {
    local dir pid ok=1
    dir="$(mktemp -d /tmp/gate_s6.XXXXXX)"
    mkdir -p "${dir}/svc"
    printf '#!/bin/sh\nexec s6-setuidgid nobody /bin/sh -c "exec sleep 300"\n' > "${dir}/svc/run"
    chmod +x "${dir}/svc/run"
    s6-svscan "${dir}" >/dev/null 2>&1 &
    pid=$!
    sleep 2
    [[ "$(s6-svstat -o up "${dir}/svc" 2>/dev/null)" == "true" ]] || { fail "G11 s6: service did not come up under s6-svscan"; ok=0; }
    if (( ok )); then
        s6-svc -wD -T 5000 -d "${dir}/svc" >/dev/null 2>&1 || { fail "G11 s6: s6-svc -wD did not stop the service"; ok=0; }
        [[ "$(s6-svstat -o up "${dir}/svc" 2>/dev/null)" == "false" ]] || { fail "G11 s6: service still up after s6-svc -d"; ok=0; }
    fi
    s6-svscanctl -t "${dir}" >/dev/null 2>&1 || true
    sleep 1
    if kill -0 "${pid}" 2>/dev/null; then
        fail "G11 s6: s6-svscan still running after s6-svscanctl -t"; ok=0
        kill "${pid}" 2>/dev/null || true
    fi
    wait "${pid}" 2>/dev/null || true
    rm -rf "${dir}"
    (( ok )) && pass "G11 s6 supervision cycle (svscan up, svc -wD stop, svscanctl -t teardown)"
}

# G10 - bake manifest records the shipped components
function gate_manifest {
    local n
    if [[ -s /etc/epics-bake.manifest ]]; then
        n="$(wc -l < /etc/epics-bake.manifest)"
        pass "G10 bake manifest present (${n} components)"
    else
        fail "G10 bake manifest missing"
    fi
}

function main {
    printf "== Container gate: %s ==\n" "${EPICS_PATH:-<EPICS_PATH unset>}"
    gate_env
    gate_inventory
    gate_symlinks
    gate_pairing
    gate_artifacts
    gate_softioc
    gate_ca
    gate_pva
    gate_linkage
    gate_tools
    gate_s6
    gate_manifest
    printf -- "-- %d passed, %d failed --\n" "${PASS_COUNT}" "${FAIL_COUNT}"
    (( FAIL_COUNT == 0 ))
}

main "$@"
