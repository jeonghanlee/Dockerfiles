#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.2.0

set -euo pipefail

SC_SCRIPT="$(realpath "$0")"
readonly SC_SCRIPT
readonly SC_TOP="${SC_SCRIPT%/*}"
readonly DOCKER_FILENAME="Dockerfile"
readonly VERSIONS_FILE="${SC_TOP}/configure/VERSIONS"

declare DOCKER_ID=""
declare TARGET_NAME=""
declare DOCKER_BUILD_OPTS=""
declare BUILD_ARGS=""

declare -a VERSION_KEYS=()
declare -A VERSION_VALUES=()

declare OPT_DRYRUN=0
declare OPT_PRINT_ARGS=0
declare cli_docker_id=""
declare cli_target_name=""
declare cli_docker_file_path=""
declare cli_docker_build_options=""
declare cli_build_args=""

function usage {
    {
        printf "\n"
        printf "Usage: %s -t <target-dir> [options]\n" "$0"
        printf "\n"
        printf "Options:\n"
        printf "  -t <dir>       Dockerfile directory under this repository\n"
        printf "  -i <id>        Docker image account or namespace\n"
        printf "  -n <name>      Docker image repository name\n"
        printf "  -o <options>   Whitespace-separated docker build options\n"
        printf "  -a <args>      Whitespace-separated build args, e.g. \"A=1 B=2\"\n"
        printf "  -d             Print the docker build command without running it\n"
        printf "  -b             Print the build args taken from configure/VERSIONS, one per line, and exit\n"
        printf "  -h             Show this help\n"
        printf "\n"
        printf "Example:\n"
        printf "  %s -d -t debian13 -a \"BUILD_DATE=<YYYY-MM-DD> BUILD_VERSION=<version>\"\n" "$0"
        printf "\n"
    } >&2
    exit 1
}

function die {
    local message="$1"

    printf "Error: %s\n" "$message" >&2
    exit 1
}

function require_command {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        die "required command not found: ${command_name}"
    fi
}

function trim_spaces {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf "%s" "$value"
}

function load_config_file {
    local config_file="$1"
    local key
    local value

    [[ -s "$config_file" ]] || die "missing or empty configuration file: ${config_file}"

    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        key="${key//$'\r'/}"
        value="${value//$'\r'/}"
        key="$(trim_spaces "$key")"

        if [[ -z "$key" || "$key" == \#* ]]; then
            continue
        fi

        case "$key" in
            DOCKER_ID)
                DOCKER_ID="$value"
                ;;
            TARGET_NAME)
                TARGET_NAME="$value"
                ;;
            DOCKER_BUILD_OPTS)
                DOCKER_BUILD_OPTS="$value"
                ;;
            BUILD_ARGS)
                BUILD_ARGS="$value"
                ;;
            *)
                die "unsupported configuration key in ${config_file}: ${key}"
                ;;
        esac
    done < "$config_file"
}

# Read configure/VERSIONS: blank lines and comment lines are skipped, every
# other line must be KEY=value with a dotted numeric value.
function load_versions {
    local line

    [[ -s "$VERSIONS_FILE" ]] || die "missing or empty versions file: ${VERSIONS_FILE}"

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"

        if [[ -z "$line" || "$line" == \#* ]]; then
            continue
        fi

        if [[ ! "$line" =~ ^([A-Z0-9_]+)=([0-9]+(\.[0-9]+)+)$ ]]; then
            die "malformed line in ${VERSIONS_FILE}: ${line}"
        fi

        VERSION_KEYS+=("${BASH_REMATCH[1]}")
        VERSION_VALUES["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
    done < "$VERSIONS_FILE"

    [[ -n "${VERSION_VALUES[IMAGE_VERSION]:-}" ]] || die "IMAGE_VERSION missing in ${VERSIONS_FILE}"
}

function dockerfile_declares {
    local dockerfile="$1"
    local key="$2"

    grep -qE "^ARG ${key}(=|\$)" "$dockerfile"
}

# Collect one KEY=value build arg for each version key the Dockerfile declares,
# plus BUILD_VERSION from IMAGE_VERSION for an image that declares IMAGE_VERSION.
function version_build_args {
    local dockerfile="$1"
    local -n args_out="$2"
    local key

    for key in "${VERSION_KEYS[@]}"; do
        if dockerfile_declares "$dockerfile" "$key"; then
            args_out+=("${key}=${VERSION_VALUES[$key]}")
        fi
    done

    if dockerfile_declares "$dockerfile" IMAGE_VERSION; then
        args_out+=("BUILD_VERSION=${VERSION_VALUES[IMAGE_VERSION]}")
    fi
}

function parse_args {
    local opt

    while getopts ":o:i:n:t:a:hdb" opt; do
        case "$opt" in
            o)
                cli_docker_build_options="$OPTARG"
                ;;
            i)
                cli_docker_id="$OPTARG"
                ;;
            n)
                cli_target_name="$OPTARG"
                ;;
            t)
                cli_docker_file_path="$OPTARG"
                ;;
            a)
                cli_build_args="$OPTARG"
                ;;
            d)
                OPT_DRYRUN=1
                ;;
            b)
                OPT_PRINT_ARGS=1
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

    if [[ $# -gt 0 ]]; then
        die "unexpected positional arguments: $*"
    fi
}

function validate_target {
    local target_dir="$1"
    local resolved_dir

    [[ -n "$target_dir" ]] || usage
    [[ "$target_dir" != /* ]] || die "target directory must be relative: ${target_dir}"
    [[ "$target_dir" != *..* ]] || die "target directory must not contain '..': ${target_dir}"

    resolved_dir="${SC_TOP}/${target_dir}"
    [[ -d "$resolved_dir" ]] || die "target directory does not exist: ${target_dir}"
    [[ -s "${resolved_dir}/${DOCKER_FILENAME}" ]] || die "missing Dockerfile in target: ${target_dir}"
    [[ -s "${resolved_dir}/env.conf" ]] || die "missing env.conf in target: ${target_dir}"
}

function apply_cli_overrides {
    if [[ -n "$cli_docker_build_options" ]]; then
        DOCKER_BUILD_OPTS="$cli_docker_build_options"
        printf "Using input docker build options: %s\n" "$DOCKER_BUILD_OPTS"
    else
        printf "Using configured docker build options: %s\n" "$DOCKER_BUILD_OPTS"
    fi

    if [[ -n "$cli_docker_id" ]]; then
        DOCKER_ID="$cli_docker_id"
        printf "Using input docker id: %s\n" "$DOCKER_ID"
    else
        printf "Using configured docker id: %s\n" "$DOCKER_ID"
    fi

    if [[ -n "$cli_target_name" ]]; then
        TARGET_NAME="$cli_target_name"
        printf "Using input target name: %s\n" "$TARGET_NAME"
    else
        printf "Using configured target name: %s\n" "$TARGET_NAME"
    fi

    if [[ -n "$cli_build_args" ]]; then
        BUILD_ARGS="$cli_build_args"
        printf "Using input build args: %s\n" "$BUILD_ARGS"
    else
        printf "Using configured build args: %s\n" "$BUILD_ARGS"
    fi
}

function append_words {
    local source="$1"
    local -n target_array="$2"
    local -a words=()
    local word

    if [[ -z "$source" ]]; then
        return 0
    fi

    read -r -a words <<< "$source"
    for word in "${words[@]}"; do
        target_array+=("$word")
    done
}

function print_command {
    local -a command=("$@")
    local separator=""
    local word

    for word in "${command[@]}"; do
        printf "%s%q" "$separator" "$word"
        separator=" "
    done
    printf "\n"
}

function build_image {
    local src_top="${SC_TOP}/${cli_docker_file_path}"
    local target_image="${DOCKER_ID}/${TARGET_NAME}"
    local -a command=(docker build)
    local -a docker_options=()
    local -a build_args=()
    local build_arg

    [[ -n "$DOCKER_ID" ]] || die "DOCKER_ID is empty"
    [[ -n "$TARGET_NAME" ]] || die "TARGET_NAME is empty"

    load_versions

    # Version args come first, so env.conf and CLI build args override them.
    version_build_args "${src_top}/${DOCKER_FILENAME}" build_args
    append_words "$DOCKER_BUILD_OPTS" docker_options
    append_words "$BUILD_ARGS" build_args

    command+=("${docker_options[@]}")
    command+=(--file "$DOCKER_FILENAME" -t "$target_image")

    # The version tag lets a runner or slim build that starts FROM
    # <name>:<IMAGE_VERSION> resolve to this local build, not a pulled image.
    if dockerfile_declares "${src_top}/${DOCKER_FILENAME}" IMAGE_VERSION; then
        command+=(-t "${target_image}:${VERSION_VALUES[IMAGE_VERSION]}")
    fi

    for build_arg in "${build_args[@]}"; do
        command+=(--build-arg "$build_arg")
    done

    command+=(.)

    print_command "${command[@]}"

    if (( OPT_DRYRUN )); then
        return 0
    fi

    require_command docker
    (
        cd "$src_top"
        "${command[@]}"
    )
}

function main {
    local target_config
    local target_local_config

    parse_args "$@"
    validate_target "$cli_docker_file_path"

    if (( OPT_PRINT_ARGS )); then
        local -a print_args=()

        load_versions
        version_build_args "${SC_TOP}/${cli_docker_file_path}/${DOCKER_FILENAME}" print_args
        if (( ${#print_args[@]} )); then
            printf "%s\n" "${print_args[@]}"
        fi
        return 0
    fi

    target_config="${SC_TOP}/${cli_docker_file_path}/env.conf"
    target_local_config="${SC_TOP}/${cli_docker_file_path}/env.local"

    load_config_file "$target_config"

    if [[ -r "$target_local_config" ]]; then
        printf "Using local configuration override: %s\n" "$target_local_config"
        load_config_file "$target_local_config"
    fi

    apply_cli_overrides
    build_image
}

main "$@"
