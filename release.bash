#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.1.0

set -euo pipefail

SC_SCRIPT="$(realpath "$0")"
readonly SC_SCRIPT
readonly SC_TOP="${SC_SCRIPT%/*}"
readonly ACTION_PATH="${SC_TOP}/.github/workflows"

declare OPT_FORCE=0
declare OPT_DRYRUN=0
declare input_tag=""

readonly -a RELEASE_WORKFLOWS=(
    "debian12.yml"
    "debian13.yml"
    "rocky8.yml"
    "rocky9.yml"
    "rocky10.yml"
)

function usage {
    {
        printf "\n"
        printf "Usage: %s [options] [tag]\n" "$0"
        printf "\n"
        printf "Options:\n"
        printf "  -f             Use the default latest tag without prompting\n"
        printf "  -n             Print changes without editing workflow files\n"
        printf "  -h             Show this help\n"
        printf "\n"
        printf "Examples:\n"
        printf "  %s 2.6.0\n" "$0"
        printf "  %s -f\n" "$0"
        printf "\n"
    } >&2
    exit 1
}

function die {
    local message="$1"

    printf "Error: %s\n" "$message" >&2
    exit 1
}

function parse_args {
    local opt

    while getopts ":fnh" opt; do
        case "$opt" in
            f)
                OPT_FORCE=1
                ;;
            n)
                OPT_DRYRUN=1
                ;;
            h)
                usage
                ;;
            :)
                die "option -${OPTARG} requires an argument"
                ;;
            \?)
                die "invalid option: -${OPTARG}"
                ;;
            *)
                usage
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [[ $# -gt 1 ]]; then
        die "only one tag argument is supported"
    fi

    input_tag="${1:-}"
}

function confirm_latest_tag {
    local answer=""

    if [[ -n "$input_tag" ]]; then
        return 0
    fi

    input_tag="latest"

    if (( OPT_FORCE )); then
        printf "Using default tag: %s\n" "$input_tag"
        return 0
    fi

    if [[ ! -t 0 ]]; then
        die "no tag provided and stdin is not interactive; use -f to select latest"
    fi

    printf "> Default latest tag will be used.\n"
    printf ">> Do you want to continue (y/N)? "
    read -r answer

    case "${answer:0:1}" in
        y|Y)
            printf "Using default tag: %s\n" "$input_tag"
            ;;
        *)
            die "provide a tag argument or use -f to select latest"
            ;;
    esac
}

function replace_tag {
    local tag="$1"
    local file="$2"
    local tmp_file

    [[ -s "$file" ]] || die "missing workflow file: ${file}"
    grep -q '^[[:space:]]*DOCKER_TAG:' "$file" || die "DOCKER_TAG not found in ${file}"

    if (( OPT_DRYRUN )); then
        printf "Would set %s DOCKER_TAG to %s\n" "$file" "$tag"
        return 0
    fi

    tmp_file="$(mktemp "${file}.XXXXXX")"
    sed -E "s|^([[:space:]]*DOCKER_TAG:).*$|\\1 ${tag}|" "$file" > "$tmp_file"
    cat "$tmp_file" > "$file"
    rm -f "$tmp_file"

    grep -q "^[[:space:]]*DOCKER_TAG: ${tag}$" "$file" || die "failed to update ${file}"
}

function update_workflows {
    local workflow
    local file

    for workflow in "${RELEASE_WORKFLOWS[@]}"; do
        file="${ACTION_PATH}/${workflow}"
        replace_tag "$input_tag" "$file"
    done
}

function main {
    parse_args "$@"
    confirm_latest_tag
    update_workflows
}

main "$@"
