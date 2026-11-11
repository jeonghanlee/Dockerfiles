#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.2.0
#
# Verify that configure/VERSIONS is the only place an EPICS image version is
# written, and that every consumer reads it. The image lists come from the
# environment (RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, SLIM_IMAGE_DIRS), as
# `make check-versions` passes them.

set -uo pipefail

SC_SCRIPT="$(realpath "$0")"
readonly SC_SCRIPT
readonly SC_TOP="${SC_SCRIPT%/*}"
readonly VERSIONS_FILE="${SC_TOP}/configure/VERSIONS"
readonly WORKFLOW_DIR="${SC_TOP}/.github/workflows"

declare -i ERRORS=0

function error { printf "error: %s\n" "$1"; ERRORS+=1; }

# Print a file without its comment lines, so a key named only in a comment
# never satisfies a check.
function code_lines { grep -v '^[[:space:]]*#' "$1"; }

function check_manifest {
    local line

    [[ -s "$VERSIONS_FILE" ]] || { error "missing or empty configure/VERSIONS"; return; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" =~ ^[A-Z0-9_]+=[0-9]+(\.[0-9]+)+$ ]] || error "configure/VERSIONS: malformed line: ${line}"
    done < "$VERSIONS_FILE"
}

function check_dockerfile_common {
    local dir="$1" file="${SC_TOP}/$1/Dockerfile" key hit

    hit="$(code_lines "$file" | grep -nE '^ARG [A-Z0-9_]+_VERSION=|/opt/epics/[0-9]')"
    [[ -z "$hit" ]] || error "${dir}/Dockerfile pins a version: ${hit}"

    for key in $(code_lines "$file" | grep -oE '^ARG [A-Z0-9_]+_VERSION$' | cut -d' ' -f2); do
        [[ "$key" == BUILD_VERSION ]] && continue
        grep -q "^${key}=" "$VERSIONS_FILE" || error "configure/VERSIONS lacks ${key}, declared in ${dir}/Dockerfile"
    done
}

function check_release_guard {
    local dir="$1" file="${SC_TOP}/$1/Dockerfile" guard key

    guard="$(code_lines "$file" | awk '/^RUN for v in /,/^[[:space:]]*done[[:space:]]*$/')"
    [[ -n "$guard" ]] || { error "${dir}/Dockerfile has no version guard"; return; }
    for key in $(code_lines "$file" | grep -oE '^ARG [A-Z0-9_]+_VERSION$' | cut -d' ' -f2); do
        [[ "$key" == BUILD_VERSION ]] && continue
        grep -qF "\"\${${key}}\"" <<< "$guard" || error "${dir}/Dockerfile guard does not list ${key}"
    done
}

function check_supervised {
    local dir="$1" file="${SC_TOP}/$1/Dockerfile"

    [[ "$(head -n 1 "$file")" == "# check=skip=InvalidDefaultArgInFrom" ]] \
        || error "${dir}/Dockerfile line 1 is not the InvalidDefaultArgInFrom skip"
    grep -q '^ARG IMAGE_VERSION$' "$file" || error "${dir}/Dockerfile does not declare ARG IMAGE_VERSION"
    grep -qE '^FROM jeonghanlee/[a-z0-9]+-epics:\$\{IMAGE_VERSION\}' "$file" \
        || error "${dir}/Dockerfile does not build FROM the IMAGE_VERSION base"
    code_lines "$file" | grep -qF 'test -n "${RUNNER_VERSION}"' \
        || error "${dir}/Dockerfile lacks the RUNNER_VERSION test"
}

# Each path must appear exactly once in the push block and once in the
# pull_request block of the per-OS workflow.
function check_workflow_filters {
    local dir="$1" file="${WORKFLOW_DIR}/$1.yml" path
    shift

    [[ -f "$file" ]] || { error "missing workflow ${dir}.yml"; return; }
    for path in configure/VERSIONS docker_builder.bash "$@"; do
        awk -v p="$path" '
            /^  [a-z_]+:/ { block = $1 }
            $0 == "      - \"" p "\"" { n[block]++ }
            END { exit !(n["push:"] == 1 && n["pull_request:"] == 1) }
        ' "$file" || error "${dir}.yml needs ${path} once in each of the push and pull_request path filters"
    done
}

# A runner or slim image builds FROM the image of its base directory, the
# directory name before "-epics-". Its workflow builds that base in the same
# job (base_dir) and reruns when the base directory changes.
function check_base_link {
    local dir="$1" base="${1%%-epics-*}" image id name
    local file="${SC_TOP}/$1/Dockerfile" wf="${WORKFLOW_DIR}/$1.yml"

    [[ -f "${SC_TOP}/${base}/env.conf" ]] || { error "${dir}: no base directory ${base}"; return; }
    id="$(sed -n 's/^DOCKER_ID=//p' "${SC_TOP}/${base}/env.conf")"
    name="$(sed -n 's/^TARGET_NAME=//p' "${SC_TOP}/${base}/env.conf")"
    image="${id}/${name}"
    grep -qE "^FROM ${image}:\\\$\{IMAGE_VERSION\}( |$)" "$file" \
        || error "${dir}/Dockerfile does not build FROM ${image}, the image of ${base}"
    [[ "$(code_lines "$wf" | grep -cxF "      base_dir: ${base}")" == 1 ]] \
        || error "${dir}.yml does not pass base_dir: ${base} once"
    check_workflow_filters "$dir" "${base}/**"
}

function check_ci_readers {
    local wf

    for wf in image.yml publish.yml release-image.yml; do
        code_lines "${WORKFLOW_DIR}/${wf}" | grep -q 'docker_builder.bash -t "${IMAGE_DIR}" -b' \
            || error "${wf} does not take its build args from docker_builder.bash -b"
    done
}

function main {
    local dir

    check_manifest
    for dir in ${RELEASE_IMAGE_DIRS:?} ${RUNNER_IMAGE_DIRS:?} ${SLIM_IMAGE_DIRS:?}; do
        check_dockerfile_common "$dir"
        check_workflow_filters "$dir"
    done
    for dir in ${RELEASE_IMAGE_DIRS}; do
        check_release_guard "$dir"
    done
    for dir in ${RUNNER_IMAGE_DIRS} ${SLIM_IMAGE_DIRS}; do
        check_supervised "$dir"
        check_base_link "$dir"
    done
    check_ci_readers

    (( ERRORS == 0 )) && printf "%s\n" "Versions: OK"
    (( ERRORS == 0 ))
}

main "$@"
