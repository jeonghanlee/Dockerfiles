#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.1
#
# Measure the four size axes of docs/IMAGE_FOOTPRINT.md for the published
# images at one tag and print the History table rows to add.
#
#   footprint.bash <version>
#
# The image directories come from FOOTPRINT_IMAGE_DIRS in the environment, as
# make passes it. Each image is pulled from Docker Hub at <version>; a pull
# replaces a local image with the same tag. Download is read from the Docker Hub
# API, since `docker image inspect` reports Disk usage with the containerd image
# store.

set -uo pipefail

SC_SCRIPT="$(realpath "$0")"
readonly SC_SCRIPT
readonly SC_TOP="${SC_SCRIPT%/*}"

function die { printf "error: %s\n" "$1" >&2; exit 2; }

# Print the value of one KEY=value line from an image env.conf.
function envconf_value {
    local file="$1" key="$2" line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "${key}="* ]] && { printf "%s\n" "${line#*=}"; return 0; }
    done < "$file"
    return 1
}

# Convert a docker size such as 1.26GB, 980MB, or 512kB to whole MB.
function size_to_mb {
    local value="$1" number unit

    [[ "$value" =~ ^([0-9.]+)([kMGT]?B)$ ]] || return 1
    number="${BASH_REMATCH[1]}" unit="${BASH_REMATCH[2]}"
    case "$unit" in
        B)  awk -v n="$number" 'BEGIN { printf "%.0f\n", n / 1e6 }' ;;
        kB) awk -v n="$number" 'BEGIN { printf "%.0f\n", n / 1e3 }' ;;
        MB) awk -v n="$number" 'BEGIN { printf "%.0f\n", n }' ;;
        GB) awk -v n="$number" 'BEGIN { printf "%.0f\n", n * 1e3 }' ;;
        TB) awk -v n="$number" 'BEGIN { printf "%.0f\n", n * 1e6 }' ;;
    esac
}

function measure {
    local version="$1" dir id name repo image url out code
    local -a dirs real=() download=() layers=() disk=() epics=()

    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must have the form X.Y.Z: ${version}"
    read -r -a dirs <<< "${FOOTPRINT_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "FOOTPRINT_IMAGE_DIRS is empty"
    command -v docker > /dev/null || die "docker not found"
    command -v jq > /dev/null || die "jq not found"

    for dir in "${dirs[@]}"; do
        id="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)" || die "${dir}/env.conf lacks DOCKER_ID"
        name="$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)" || die "${dir}/env.conf lacks TARGET_NAME"
        repo="${id}/${name}"
        image="${repo}:${version}"
        printf "measuring %s\n" "$image" >&2
        docker pull -q "$image" > /dev/null || die "cannot pull ${image}"

        # --entrypoint du keeps the measurement independent of the image's
        # own entry point, such as s6-svscan in a runner or slim image.
        out="$(docker run --rm --entrypoint du "$image" -sxm /)" || die "du failed in ${image}"
        real+=("${out%%[[:space:]]*}")
        out="$(docker run --rm --entrypoint du "$image" -sxm /opt/epics)" || die "du /opt/epics failed in ${image}"
        epics+=("${out%%[[:space:]]*}")

        url="https://hub.docker.com/v2/repositories/${repo}/tags/${version}"
        out="$(curl -sS -w '\n%{http_code}' "$url")" || die "cannot read ${url}"
        code="${out##*$'\n'}"
        [[ "$code" == 200 ]] || die "Docker Hub answered ${code} for ${url}"
        out="$(jq -r '.full_size / 1e6 | round' <<< "${out%$'\n'*}" 2> /dev/null)"
        [[ "$out" =~ ^[0-9]+$ ]] || die "Docker Hub reported no full_size for ${image}"
        download+=("$out")

        # Each layer size is a byte count; a failed history must not sum to 0.
        out="$(docker history --human=false --format '{{.Size}}' "$image")" || die "docker history failed for ${image}"
        [[ -n "$out" ]] || die "docker history listed no layers for ${image}"
        layers+=("$(awk '{ s += $1 } END { printf "%.0f\n", s / 1e6 }' <<< "$out")")
        out="$(docker images --format '{{.Size}}' "$image" | head -n 1)"
        out="$(size_to_mb "$out")" || die "cannot read the disk usage of ${image}"
        disk+=("$out")
    done

    local date docker_version store header
    date="$(date -u +%F)"
    docker_version="$(docker version --format '{{.Server.Version}}')"
    store="$(docker info --format '{{json .DriverStatus}}' | jq -r 'map(select(.[0] == "driver-type")) | .[0][1] // "classic"')"
    header="$(printf '| %s ' "${dirs[@]}")"

    printf "Measured %s with Docker %s (image store: %s), tags %s pulled from Docker Hub.\n\n" \
        "$date" "$docker_version" "$store" "$version"
    printf "Columns: | Distribution | Date %s| Note |\n\n" "$header"
    printf "Real files:\n";  printf "| %s | %s " "$version" "$date"; printf "| %s MB " "${real[@]}";     printf "| Published %s, pulled |\n\n" "$version"
    printf "Download:\n";    printf "| %s | %s " "$version" "$date"; printf "| %s MB " "${download[@]}"; printf "| Published %s, Docker Hub \`full_size\` |\n\n" "$version"
    printf "Layer sum:\n";   printf "| %s | %s " "$version" "$date"; printf "| %s MB " "${layers[@]}";   printf "| Published %s, pulled |\n\n" "$version"
    printf "Disk usage:\n";  printf "| %s | %s " "$version" "$date"; printf "| %s MB " "${disk[@]}";     printf "| Published %s, pulled |\n\n" "$version"
    printf "EPICS tree under /opt/epics:"; printf " %s MB" "${epics[@]}"; printf "\n"
}

(( $# == 1 )) || { printf "usage: %s <version>\n" "${0##*/}" >&2; exit 2; }
measure "$1"
