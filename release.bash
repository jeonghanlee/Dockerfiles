#!/usr/bin/env bash
#
#  author  : Jeong Han Lee
#  email   : jeonghan.lee@gmail.com
#  version : 0.10.0
#
# Release tool for the 18 EPICS images. Every subcommand is read-only.
#
#   release.bash check <version>
#       Verify that EPICS-env-distribution carries the tag <version> and, for
#       each release image, the tree <version>/<OS_DIR>/<EPICS_VERSION> that
#       its build fetches.
#
#   release.bash components
#       Compare each version a Dockerfile clones by tag with the highest X.Y.Z
#       tag of its repository. A newer tag is reported, not a failure; a
#       pinned tag absent from its repository is a failure. A key listed in
#       HELD_VERSION_KEYS is raised only for a security fix and reports a
#       newer tag as held.
#
#   release.bash status <version>
#       Report how far the release of <version> has gone, stage by stage
#       (versions, git, ci, hub, latest), and print the next action. Stages
#       after the first unfinished one are not checked unless
#       RELEASE_STATUS_ALL=1.
#
#   release.bash verify <version>
#       Verify each published image: <version> and latest share one digest,
#       and the revision label names an origin/master commit whose
#       configure/VERSIONS matches the image labels.
#
#   release.bash abandon <version>
#       Report how far the abandonment of <version> has gone (runs, local,
#       master, hub) and print the commands that remain, until GitHub and
#       Docker Hub are back at the previous version.
#
# The image lists come from RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, and
# SLIM_IMAGE_DIRS in the environment, as make passes them. A configure/VERSIONS
# key set in the environment overrides the file value.

set -uo pipefail

SC_SCRIPT="$(realpath "$0")"
readonly SC_SCRIPT
readonly SC_TOP="${SC_SCRIPT%/*}"
readonly VERSIONS_FILE="${SC_TOP}/configure/VERSIONS"

declare -i FAILURES=0
declare TMP_DIR=""

# The temporary distribution clone of the check subcommand is removed on
# success and kept for inspection on failure or with KEEP_WORKSPACE=1.
function cleanup {
    local rc=$?
    [[ -n "$TMP_DIR" ]] || return
    if (( rc != 0 )) || [[ "${KEEP_WORKSPACE:-0}" == 1 ]]; then
        printf "Workspace retained: %s\n" "$TMP_DIR" >&2
        return
    fi
    rm -rf -- "$TMP_DIR"
}
trap cleanup EXIT

function die  { printf "error: %s\n" "$1" >&2; exit 2; }
function pass { printf "PASS  %s\n" "$1"; }
function fail { printf "FAIL  %s\n" "$1"; FAILURES+=1; }
function note { printf "NOTE  %s\n" "$1"; }

function usage {
    printf "usage: %s check <version> | components | status <version> | verify <version> | abandon <version>\n" "${0##*/}" >&2
    exit 2
}

# Print the value of one configure/VERSIONS key; the environment overrides it.
function versions_value {
    local key="$1" line

    [[ -n "${!key:-}" ]] && { printf "%s\n" "${!key}"; return 0; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "${key}="* ]] && { printf "%s\n" "${line#*=}"; return 0; }
    done < "$VERSIONS_FILE"
    return 1
}

# Print the default value of one ARG from a Dockerfile.
function dockerfile_arg {
    local file="$1" key="$2" line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "ARG ${key}="* ]] && { printf "%s\n" "${line#*=}"; return 0; }
    done < "$file"
    return 1
}

function release_check {
    local version="$1" epics dir file repo os_dir found
    local -a dirs trees
    local -A used=()

    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must have the form X.Y.Z: ${version}"
    epics="$(versions_value EPICS_VERSION)"
    [[ -n "$epics" ]] || die "EPICS_VERSION is not set in configure/VERSIONS"
    read -r -a dirs <<< "${RELEASE_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "RELEASE_IMAGE_DIRS is empty"

    repo="$(dockerfile_arg "${SC_TOP}/${dirs[0]}/Dockerfile" DIST_REPO)" \
        || die "${dirs[0]}/Dockerfile declares no DIST_REPO default"
    for dir in "${dirs[@]}"; do
        [[ "$(dockerfile_arg "${SC_TOP}/${dir}/Dockerfile" DIST_REPO)" == "$repo" ]] \
            || die "${dir}/Dockerfile DIST_REPO differs from ${repo}"
    done

    # git ls-remote --exit-code returns 2 when no ref matches; any other
    # failure means the repository could not be read, not a missing tag.
    git ls-remote --exit-code --tags "$repo" "refs/tags/${version}" > /dev/null
    case $? in
        0) ;;
        2) fail "tag ${version} not found in ${repo}"; return ;;
        *) fail "cannot read ${repo}; run make release-check VERSION=${version} again once it answers"; return ;;
    esac
    pass "tag ${version} exists in ${repo}"

    TMP_DIR="$(mktemp -d)" || die "mktemp failed"
    git clone --quiet --depth 1 --filter=blob:none --no-checkout --branch "$version" "$repo" "${TMP_DIR}/dist" \
        2> /dev/null || die "clone of ${repo} at ${version} failed"

    for dir in "${dirs[@]}"; do
        file="${SC_TOP}/${dir}/Dockerfile"
        os_dir="$(dockerfile_arg "$file" OS_DIR)" || { fail "${dir}/Dockerfile declares no OS_DIR default"; continue; }
        used["$os_dir"]=1
        if git -C "${TMP_DIR}/dist" cat-file -e "HEAD:${version}/${os_dir}/${epics}" 2> /dev/null; then
            pass "$(printf "%-9s %s" "$dir" "${version}/${os_dir}/${epics}")"
        else
            found="$(git -C "${TMP_DIR}/dist" ls-tree -d --name-only "HEAD:${version}/${os_dir}" 2> /dev/null | paste -sd " ")"
            fail "$(printf "%-9s %s missing; found: %s" "$dir" "${version}/${os_dir}/${epics}" "${found:-no ${version}/${os_dir} tree}")"
        fi
    done

    mapfile -t trees < <(git -C "${TMP_DIR}/dist" ls-tree -d --name-only "HEAD:${version}" 2> /dev/null)
    for os_dir in "${trees[@]}"; do
        [[ -n "${used[$os_dir]:-}" ]] || note "${version}/${os_dir} has no image"
    done

    if (( FAILURES == 0 )); then
        printf "Release check: OK (%s, %d trees)\n" "$version" "${#dirs[@]}"
    else
        printf "Release check: %d failure(s)\n" "$FAILURES"
    fi
}

# Collect, from every image Dockerfile, the clones of the form
#   --branch "<prefix>${KEY}" <repository>
# into COMPONENT_PREFIX and COMPONENT_REPO, keyed by KEY. A repository written
# as ${NAME} resolves to the ARG NAME default of the same Dockerfile.
declare -A COMPONENT_PREFIX=() COMPONENT_REPO=()

function collect_components {
    local dir file line key prefix repo
    local -a dirs
    local re='--branch "([a-z]*)\$\{([A-Z0-9_]+)\}" "?([^" ]+)"?'

    read -r -a dirs <<< "${RELEASE_IMAGE_DIRS:-} ${RUNNER_IMAGE_DIRS:-} ${SLIM_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, and SLIM_IMAGE_DIRS are empty"

    for dir in "${dirs[@]}"; do
        file="${SC_TOP}/${dir}/Dockerfile"
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ $re ]] || continue
            prefix="${BASH_REMATCH[1]}" key="${BASH_REMATCH[2]}" repo="${BASH_REMATCH[3]}"
            if [[ "$repo" =~ ^\$\{([A-Z0-9_]+)\}$ ]]; then
                repo="$(dockerfile_arg "$file" "${BASH_REMATCH[1]}")" \
                    || die "${dir}/Dockerfile declares no ${BASH_REMATCH[1]} default"
            fi
            if [[ -n "${COMPONENT_REPO[$key]:-}" ]]; then
                [[ "${COMPONENT_REPO[$key]}" == "$repo" && "${COMPONENT_PREFIX[$key]}" == "$prefix" ]] \
                    || die "${dir}/Dockerfile clones ${key} from ${prefix}@${repo}, elsewhere ${COMPONENT_PREFIX[$key]}@${COMPONENT_REPO[$key]}"
            fi
            COMPONENT_PREFIX["$key"]="$prefix"
            COMPONENT_REPO["$key"]="$repo"
        done < "$file"
    done
}

function release_components {
    local line key pinned latest status tags
    local -a keys=() rows=() held_keys=()
    local -A held=()
    local -i w_key=3 w_pin=6 w_lat=6 n_held=0

    collect_components
    read -r -a held_keys <<< "${HELD_VERSION_KEYS:-}"
    for key in "${held_keys[@]}"; do held["$key"]=1; done

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        key="${line%%=*}"
        [[ -n "${COMPONENT_REPO[$key]:-}" ]] && keys+=("$key")
    done < "$VERSIONS_FILE"
    (( ${#keys[@]} > 0 )) || die "no Dockerfile clones a configure/VERSIONS key by tag"

    for key in "${keys[@]}"; do
        pinned="$(versions_value "$key")"
        if ! tags="$(git ls-remote --tags --refs "${COMPONENT_REPO[$key]}" 2> /dev/null)"; then
            latest="-" status="UNREACHABLE"
            FAILURES+=1
        else
            tags="$(sed -n 's|^[0-9a-f]*[[:space:]]*refs/tags/||p' <<< "$tags")"
            latest="$(sed -n "s|^${COMPONENT_PREFIX[$key]}\([0-9][0-9]*\(\.[0-9][0-9]*\)*\)$|\1|p" <<< "$tags" | sort -V | tail -n 1)"
            if ! grep -qxF "${COMPONENT_PREFIX[$key]}${pinned}" <<< "$tags"; then
                status="MISSING"
                FAILURES+=1
            elif [[ "$latest" == "$pinned" ]]; then
                status="current"
            elif [[ -n "${held[$key]:-}" ]]; then
                status="held"
                n_held+=1
            else
                status="newer"
            fi
        fi
        rows+=("${key}|${pinned}|${latest:--}|${status}|${COMPONENT_REPO[$key]}")
        (( ${#key} > w_key )) && w_key=${#key}
        (( ${#pinned} > w_pin )) && w_pin=${#pinned}
        (( ${#latest} > w_lat )) && w_lat=${#latest}
    done

    printf "%-${w_key}s  %-${w_pin}s  %-${w_lat}s  %-11s  %s\n" Key Pinned Latest Status Repository
    printf "%-${w_key}s  %-${w_pin}s  %-${w_lat}s  %-11s  %s\n" \
        "$(printf '%*s' "$w_key" '' | tr ' ' -)" "$(printf '%*s' "$w_pin" '' | tr ' ' -)" \
        "$(printf '%*s' "$w_lat" '' | tr ' ' -)" "-----------" "----------"
    for line in "${rows[@]}"; do
        IFS='|' read -r key pinned latest status tags <<< "$line"
        printf "%-${w_key}s  %-${w_pin}s  %-${w_lat}s  %-11s  %s\n" "$key" "$pinned" "$latest" "$status" "$tags"
    done
    (( n_held == 0 )) || printf "held: raise only for a security fix (HELD_VERSION_KEYS in configure/CONFIG_SITE)\n"

    if (( FAILURES == 0 )); then
        printf "Components: OK (%d checked)\n" "${#rows[@]}"
    else
        printf "Components: %d failure(s)\n" "$FAILURES"
    fi
}

# Print the value of one KEY=value line from an image env.conf.
function envconf_value {
    local file="$1" key="$2" line

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "${key}="* ]] && { printf "%s\n" "${line#*=}"; return 0; }
    done < "$file"
    return 1
}

# Print the push path filters of a workflow as git pathspecs; "dir/**" becomes
# "dir/" and the .trigger tree, which forces a run without changing an image,
# is left out.
function workflow_paths {
    awk '/^  push:/ { p = 1; next } /^  [a-z_]+:/ { p = 0 }
         p && /^      - "/ { gsub(/^      - "|"$/, ""); print }' "$1" |
        sed -e '/^\.trigger\//d' -e 's|/\*\*$|/|'
}

# Print the Docker Hub digest of <repository>:<tag>, or nothing when the tag
# does not exist. Return 1 when the registry cannot be read.
function hub_digest {
    local repo="$1" tag="$2" out code

    out="$(curl -sS -w '\n%{http_code}' "https://hub.docker.com/v2/repositories/${repo}/tags/${tag}" 2> /dev/null)" || return 1
    code="${out##*$'\n'}"
    case "$code" in
        200) jq -r '.digest // empty' <<< "${out%$'\n'*}" ;;
        404) ;;
        *)   return 1 ;;
    esac
}

function stage {
    printf "%-4s  %-9s  %s\n" "$1" "$2" "$3"
}

function release_status {
    local version="$1" dist image head origin dir wf sha state conclusion repo digest out other next="" slug
    local run_id run_state run_end run_sha
    local -a dirs paths runs ci_bad=() ci_none=() ci_stale=() ci_error=() hub_missing=() hub_error=()
    local -a latest_bad=() latest_error=()
    local -A tag_digest=() tag_error=()
    local -i all=0 ci_ok=0 stop=0 ahead=0 behind=0 tagged=0

    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must have the form X.Y.Z: ${version}"
    [[ "${RELEASE_STATUS_ALL:-}" == 1 ]] && all=1
    slug="$(github_slug)" || die "origin is not a GitHub repository; set GH_REPO"
    read -r -a dirs <<< "${RELEASE_IMAGE_DIRS:-} ${RUNNER_IMAGE_DIRS:-} ${SLIM_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, and SLIM_IMAGE_DIRS are empty"

    # Stage 1: versions.
    dist="$(versions_value DIST_VERSION)" image="$(versions_value IMAGE_VERSION)"
    if [[ "$dist" == "$version" && "$image" == "$version" ]]; then
        stage PASS versions "DIST_VERSION=${dist} IMAGE_VERSION=${image}"
    else
        stage FAIL versions "DIST_VERSION=${dist} IMAGE_VERSION=${image}, expected ${version}"
        # A checkout behind origin/master reads an old configure/VERSIONS, and
        # a version that Docker Hub already carries was released or abandoned
        # before; neither starts a new release at step 1.
        head="$(git -C "$SC_TOP" rev-parse HEAD)"
        origin="$(git -C "$SC_TOP" ls-remote origin refs/heads/master 2> /dev/null | cut -f1)"
        if [[ -n "$origin" && "$head" != "$origin" ]] \
            && ! git -C "$SC_TOP" merge-base --is-ancestor "$origin" "$head" 2> /dev/null; then
            if git -C "$SC_TOP" cat-file -e "${origin}^{commit}" 2> /dev/null; then
                next="pull origin/master: git -C ${SC_TOP} pull --ff-only (owner), then run make release-status VERSION=${version} again"
            else
                next="fetch origin/master: git -C ${SC_TOP} fetch (agent), then run make release-status VERSION=${version} again"
            fi
        else
            tagged=0
            for dir in "${dirs[@]}"; do
                repo="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)/$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)"
                digest="$(hub_digest "$repo" "$version")" && [[ -n "$digest" ]] && tagged+=1
            done
            if (( tagged > 0 )); then
                next="stop and ask the owner: Docker Hub already has ${version} for ${tagged} image(s), from an earlier release or an abandoned one; make release-status VERSION=${version} ALL=1 shows them"
            else
                next="make release-check VERSION=${version}, then make dist-version.${version}"
            fi
        fi
        stop=1
    fi

    # Stage 2: git. Position against origin/master comes first: a checkout
    # behind it must not commit a release change that origin may already have.
    if (( stop == 0 || all == 1 )); then
        head="$(git -C "$SC_TOP" rev-parse HEAD)"
        origin="$(git -C "$SC_TOP" ls-remote origin refs/heads/master 2> /dev/null | cut -f1)"
        out="$(git -C "$SC_TOP" status --porcelain)"
        other="$(grep -v ' configure/VERSIONS$' <<< "$out" | cut -c4- | paste -sd' ')"
        ahead=0 behind=0
        if [[ -z "$origin" ]]; then
            stage FAIL git "cannot read origin/master"
            [[ -n "$next" ]] || next="restore access to origin, then run make release-status VERSION=${version} again"
        elif [[ "$head" != "$origin" ]] && ! git -C "$SC_TOP" cat-file -e "${origin}^{commit}" 2> /dev/null; then
            stage FAIL git "origin/master ${origin:0:7} is not in the local clone"
            [[ -n "$next" ]] || next="fetch origin/master: git -C ${SC_TOP} fetch (agent), then run make release-status VERSION=${version} again"
        else
            [[ "$head" == "$origin" ]] \
                || read -r ahead behind < <(git -C "$SC_TOP" rev-list --left-right --count "${head}...${origin}")
            if (( behind > 0 )) && [[ -n "$out" ]]; then
                stage FAIL git "HEAD ${head:0:7} is ${behind} commit(s) behind origin/master ${origin:0:7}, with uncommitted changes"
                if [[ "$(image_version_at "$origin")" == "$version" ]]; then
                    [[ -n "$next" ]] || next="stop and ask the owner: origin/master already has IMAGE_VERSION=${version}, so the local change is not needed; on yes, git -C ${SC_TOP} restore configure/VERSIONS (agent), then git -C ${SC_TOP} pull --ff-only (owner)"
                else
                    [[ -n "$next" ]] || next="stop and ask the owner how to bring the uncommitted changes onto origin/master ${origin:0:7}"
                fi
            elif (( behind > 0 && ahead == 0 )); then
                stage FAIL git "HEAD ${head:0:7} is ${behind} commit(s) behind origin/master ${origin:0:7}"
                [[ -n "$next" ]] || next="pull origin/master: git -C ${SC_TOP} pull --ff-only (owner), then run make release-status VERSION=${version} again"
            elif (( behind > 0 )); then
                stage FAIL git "HEAD ${head:0:7} and origin/master ${origin:0:7} diverged (${ahead} ahead, ${behind} behind)"
                [[ -n "$next" ]] || next="stop and ask the owner how to reconcile HEAD with origin/master"
            elif [[ -n "$other" ]]; then
                # Only a configure/VERSIONS change is the release change; any
                # other uncommitted path is work the owner decides about.
                stage FAIL git "uncommitted paths that are not the release change: ${other}"
                [[ -n "$next" ]] || next="stop and ask the owner about the uncommitted paths"
            elif [[ -n "$out" ]]; then
                stage FAIL git "uncommitted release change in configure/VERSIONS"
                [[ -n "$next" ]] || next="commit and push the release change (owner), as step 5 describes"
            elif (( ahead > 0 )); then
                stage FAIL git "HEAD ${head:0:7} is ${ahead} commit(s) ahead of origin/master ${origin:0:7}"
                [[ -n "$next" ]] || next="push HEAD: git -C ${SC_TOP} push (owner), then run make release-status VERSION=${version} again"
            else
                stage PASS git "clean, HEAD ${head:0:7} = origin/master"
            fi
        fi
        [[ "$(git -C "$SC_TOP" status --porcelain)" == "" && -n "$origin" && "$head" == "$origin" ]] || stop=1
    else
        stage .... git "not checked"
    fi

    # Stage 3: ci. A workflow covers HEAD when its latest master run on an
    # ancestor of HEAD succeeded and no file under its push path filters
    # changed between that run and HEAD.
    if (( stop == 0 || all == 1 )); then
        head="$(git -C "$SC_TOP" rev-parse HEAD)"
        for dir in "${dirs[@]}"; do
            wf="${SC_TOP}/.github/workflows/${dir}.yml"
            mapfile -t paths < <(workflow_paths "$wf")
            if ! out="$(cd "$SC_TOP" && gh run list --workflow "${dir}.yml" --branch master \
                --limit 30 --json headSha,status,conclusion \
                --jq '.[] | "\(.headSha) \(.status) \(.conclusion)"' 2> /dev/null)"; then
                ci_error+=("$dir")
                continue
            fi
            mapfile -t runs <<< "$out"
            sha=""
            for state in "${runs[@]}"; do
                [[ -n "$state" ]] || continue
                read -r sha state conclusion <<< "$state"
                git -C "$SC_TOP" merge-base --is-ancestor "$sha" "$head" 2> /dev/null && break
                sha=""
            done
            if [[ -z "$sha" ]]; then
                ci_none+=("$dir")
            elif [[ "$state" != completed ]]; then
                ci_bad+=("${dir}(${state})")
            elif [[ "$conclusion" != success ]]; then
                ci_bad+=("${dir}(${conclusion})")
            elif ! git -C "$SC_TOP" diff --quiet "$sha" "$head" -- "${paths[@]}"; then
                ci_stale+=("$dir")
            else
                ci_ok+=1
            fi
        done
        if (( ci_ok == ${#dirs[@]} )); then
            stage PASS ci "${ci_ok}/${#dirs[@]} covered by a successful run"
        else
            stage FAIL ci "${ci_ok}/${#dirs[@]} covered${ci_bad[*]:+; not successful: ${ci_bad[*]}}${ci_stale[*]:+; changed since the last run: ${ci_stale[*]}}${ci_none[*]:+; no master run: ${ci_none[*]}}${ci_error[*]:+; gh cannot read the runs: ${ci_error[*]}}"
            if [[ -z "$next" ]]; then
                if (( ${#ci_error[@]} > 0 )); then
                    next="check gh auth status, then run make release-status VERSION=${version} again"
                elif (( ${#ci_bad[@]} > 0 )); then
                    next="wait for the running workflows, or fix the failed ones, then run make release-status VERSION=${version} again"
                else
                    next="start each listed workflow: gh workflow run <image_dir>.yml -R ${slug} --ref master (owner), then run make release-status VERSION=${version} again"
                fi
            fi
            stop=1
        fi
    else
        stage .... ci "not checked"
    fi

    # Stage 4: run. The newest release.yml run must have completed, and a run
    # still going must build HEAD, the commit the ci stage covered.
    if (( stop == 0 || all == 1 )); then
        head="$(git -C "$SC_TOP" rev-parse HEAD)"
        if ! out="$(cd "$SC_TOP" && gh run list --workflow release.yml -R "$slug" --limit 1 \
            --json databaseId,status,conclusion,headSha \
            --jq '.[] | "\(.databaseId) \(.status) \(.conclusion) \(.headSha)"' 2>&1)"; then
            if [[ "$out" == *"HTTP 404"* ]]; then
                stage PASS run "no release run: release.yml is not on the default branch"
            else
                stage FAIL run "gh cannot read the release runs"
                [[ -n "$next" ]] || next="check gh auth status (agent), then run make release-status VERSION=${version} again"
                stop=1
            fi
        elif [[ -z "$out" ]]; then
            stage PASS run "no release run yet"
        else
            read -r run_id run_state run_end run_sha <<< "$out"
            if [[ "$run_state" == completed ]]; then
                stage PASS run "newest release run ${run_id} completed (${run_end}) on ${run_sha:0:7}"
            elif [[ "$run_sha" == "$head" ]]; then
                stage FAIL run "release run ${run_id} is ${run_state} on HEAD ${head:0:7}"
                [[ -n "$next" ]] || next="wait for release run ${run_id}: gh run watch ${run_id} -R ${slug} (owner), then run make release-status VERSION=${version} again"
                stop=1
            else
                stage FAIL run "release run ${run_id} is ${run_state} on ${run_sha:0:7}, not HEAD ${head:0:7}"
                [[ -n "$next" ]] || next="cancel release run ${run_id}: gh run cancel ${run_id} -R ${slug} (owner), then continue at step 6"
                stop=1
            fi
        fi
    else
        stage .... run "not checked"
    fi

    # Stage 5: hub.
    if (( stop == 0 || all == 1 )); then
        for dir in "${dirs[@]}"; do
            repo="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)/$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)"
            if ! digest="$(hub_digest "$repo" "$version")"; then
                hub_error+=("$dir")
                tag_error["$dir"]=1
            elif [[ -z "$digest" ]]; then
                hub_missing+=("$dir")
            else
                tag_digest["$dir"]="$digest"
            fi
        done
        if (( ${#tag_digest[@]} == ${#dirs[@]} )); then
            stage PASS hub "${#dirs[@]}/${#dirs[@]} carry tag ${version}"
        else
            stage FAIL hub "${#tag_digest[@]}/${#dirs[@]} carry tag ${version}${hub_missing[*]:+; missing: ${hub_missing[*]}}${hub_error[*]:+; unreadable: ${hub_error[*]}}"
            if [[ -z "$next" ]]; then
                if (( ${#hub_error[@]} > 0 )); then
                    next="Docker Hub could not be read; run make release-status VERSION=${version} again once it answers"
                else
                    next="run the release workflow (owner), then run make release-status VERSION=${version} again"
                fi
            fi
            stop=1
        fi
    else
        stage .... hub "not checked"
    fi

    # Stage 6: latest.
    if (( stop == 0 || all == 1 )); then
        for dir in "${dirs[@]}"; do
            [[ -n "${tag_error[$dir]:-}" ]] && { latest_error+=("$dir"); continue; }
            [[ -n "${tag_digest[$dir]:-}" ]] || { latest_bad+=("$dir"); continue; }
            repo="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)/$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)"
            if ! digest="$(hub_digest "$repo" latest)"; then
                latest_error+=("$dir")
            elif [[ "$digest" != "${tag_digest[$dir]}" ]]; then
                latest_bad+=("$dir")
            fi
        done
        if (( ${#latest_bad[@]} + ${#latest_error[@]} == 0 )); then
            stage PASS latest "${#dirs[@]}/${#dirs[@]} latest = ${version}"
        else
            stage FAIL latest "$(( ${#dirs[@]} - ${#latest_bad[@]} - ${#latest_error[@]} ))/${#dirs[@]} latest = ${version}${latest_bad[*]:+; differs: ${latest_bad[*]}}${latest_error[*]:+; unreadable: ${latest_error[*]}}"
            if [[ -z "$next" ]]; then
                if (( ${#latest_error[@]} > 0 )); then
                    next="Docker Hub could not be read; run make release-status VERSION=${version} again once it answers"
                else
                    next="run the release workflow (owner), then run make release-status VERSION=${version} again"
                fi
            fi
            stop=1
        fi
    else
        stage .... latest "not checked"
    fi

    (( stop == 0 )) && next="make release-verify VERSION=${version}"
    printf "Next: %s\n" "$next"
    (( stop == 0 )) || FAILURES+=1
}

# Verify one published image: the version tag and latest share a digest, the
# revision label names a commit on origin/master whose configure/VERSIONS has
# IMAGE_VERSION=<version>, and every label the image Dockerfile sets from a
# version variable carries that commit's value (BUILD_VERSION is IMAGE_VERSION).
function verify_image {
    local dir="$1" version="$2" origin="$3" repo want have labels rev versions line key var expect got
    local -a bad=()

    repo="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)/$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)"
    # A registry read error, such as a rate limit, is reported as unreadable,
    # never as a missing tag or a differing digest.
    if ! want="$(hub_digest "$repo" "$version")"; then
        fail "$(printf "%-22s %s:%s unreadable; run the verify again later" "$dir" "$repo" "$version")"
        return
    fi
    [[ -n "$want" ]] || { fail "$(printf "%-22s %s:%s not found" "$dir" "$repo" "$version")"; return; }
    if ! have="$(hub_digest "$repo" latest)"; then
        bad+=("latest unreadable")
    elif [[ "$have" != "$want" ]]; then
        bad+=("latest ${have:0:19} differs")
    fi

    if ! labels="$(docker buildx imagetools inspect "${repo}:${version}" --format '{{json .Image.Config.Labels}}' 2> /dev/null)" \
        || [[ -z "$labels" ]]; then
        bad+=("labels unreadable; run the verify again later")
        rev="-"
    else
        rev="$(jq -r '."org.opencontainers.image.revision" // empty' <<< "$labels")"
    fi
    if [[ "$rev" == "-" ]]; then
        :
    elif [[ -z "$rev" ]]; then
        bad+=("no org.opencontainers.image.revision label")
    elif ! git -C "$SC_TOP" cat-file -e "${rev}^{commit}" 2> /dev/null; then
        bad+=("revision ${rev:0:7} not in the local clone; run git fetch")
    elif ! git -C "$SC_TOP" merge-base --is-ancestor "$rev" "$origin" 2> /dev/null; then
        bad+=("revision ${rev:0:7} not on origin/master")
    else
        versions="$(git -C "$SC_TOP" show "${rev}:configure/VERSIONS")"
        grep -qx "IMAGE_VERSION=${version}" <<< "$versions" \
            || bad+=("revision ${rev:0:7} has no IMAGE_VERSION=${version}")
        while IFS= read -r line; do
            [[ "$line" =~ ^LABEL\ ([a-z.-]+)=\$\{?([A-Z0-9_]+)\}?$ ]] || continue
            key="${BASH_REMATCH[1]}" var="${BASH_REMATCH[2]}"
            [[ "$var" == BUILD_VERSION ]] && var=IMAGE_VERSION
            expect="$(sed -n "s/^${var}=//p" <<< "$versions")"
            [[ -n "$expect" ]] || continue
            got="$(jq -r --arg k "$key" '.[$k] // empty' <<< "$labels")"
            [[ "$got" == "$expect" ]] || bad+=("${key}=${got:-none}, expected ${expect}")
        done < <(git -C "$SC_TOP" show "${rev}:${dir}/Dockerfile")
    fi

    if (( ${#bad[@]} == 0 )); then
        pass "$(printf "%-22s %s = latest %s  rev %s" "$dir" "$version" "${want:0:19}" "${rev:0:7}")"
    else
        local IFS=';'
        fail "$(printf "%-22s %s" "$dir" "${bad[*]}")"
    fi
}

function release_verify {
    local version="$1" origin dir
    local -a dirs

    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must have the form X.Y.Z: ${version}"
    read -r -a dirs <<< "${RELEASE_IMAGE_DIRS:-} ${RUNNER_IMAGE_DIRS:-} ${SLIM_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, and SLIM_IMAGE_DIRS are empty"
    origin="$(git -C "$SC_TOP" ls-remote origin refs/heads/master 2> /dev/null | cut -f1)"
    [[ -n "$origin" ]] || die "cannot read origin/master"

    for dir in "${dirs[@]}"; do
        verify_image "$dir" "$version" "$origin"
    done

    if (( FAILURES == 0 )); then
        printf "Release verify: OK (%s, %d images)\n" "$version" "${#dirs[@]}"
    else
        printf "Release verify: %d failure(s)\n" "$FAILURES"
    fi
}

# Print the owner/name GitHub slug of origin; GH_REPO, the variable gh itself
# reads, names it for a checkout whose origin is not GitHub.
function github_slug {
    local url
    [[ -n "${GH_REPO:-}" ]] && { printf "%s\n" "$GH_REPO"; return 0; }
    url="$(git -C "$SC_TOP" remote get-url origin 2> /dev/null)" || return 1
    url="${url%.git}"
    [[ "$url" =~ github\.com[:/]([^/]+/[^/]+)$ ]] || return 1
    printf "%s\n" "${BASH_REMATCH[1]}"
}

# Print the IMAGE_VERSION of configure/VERSIONS at a commit, or nothing when the
# commit has no such file.
function image_version_at {
    git -C "$SC_TOP" show "${1}:configure/VERSIONS" 2> /dev/null | sed -n 's/^IMAGE_VERSION=//p'
}

function next_lines {
    local line
    printf "Next:\n"
    for line in "$@"; do printf "  %s\n" "$line"; done
}

# Report how far the abandonment of <version> has gone and print the actions
# that remain, stage by stage: runs, local, master, hub. Each stage is checked
# only after the stages before it are finished, since its answer depends on
# them. The previous version is the IMAGE_VERSION that latest returns to: the
# value before the release commit while the release is on origin/master, and
# the origin/master value once it is not.
function release_abandon {
    local version="$1" slug repo origin head out id st prev rel line dir digest want
    local -a dirs runs waiting=() running=() dirty=() local_commits=() list=() acts=()
    local -i ahead=0 behind=0

    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must have the form X.Y.Z: ${version}"
    read -r -a dirs <<< "${RELEASE_IMAGE_DIRS:-} ${RUNNER_IMAGE_DIRS:-} ${SLIM_IMAGE_DIRS:-}"
    (( ${#dirs[@]} > 0 )) || die "RELEASE_IMAGE_DIRS, RUNNER_IMAGE_DIRS, and SLIM_IMAGE_DIRS are empty"
    slug="$(github_slug)" || die "origin is not a GitHub repository"

    # Stage 1: runs. A release run that has not completed keeps pushing tags.
    if ! out="$(cd "$SC_TOP" && gh run list --workflow release.yml -R "$slug" --limit 20 \
        --json databaseId,status --jq '.[] | "\(.databaseId) \(.status)"' 2>&1)"; then
        if [[ "$out" == *"HTTP 404"* ]]; then
            stage PASS runs "release.yml is not on the default branch; no release run exists"
        else
            stage FAIL runs "gh cannot read the release runs"
            next_lines "check gh auth status (agent), then run make release-abandon-status VERSION=${version} again (agent)"
            FAILURES+=1
            return
        fi
    else
        mapfile -t runs <<< "$out"
        for line in "${runs[@]}"; do
            [[ -n "$line" ]] || continue
            read -r id st <<< "$line"
            case "$st" in
                completed)   ;;
                in_progress) running+=("$id") ;;
                *)           waiting+=("$id") ;;
            esac
        done
        if (( ${#waiting[@]} + ${#running[@]} > 0 )); then
            stage FAIL runs "not completed: ${waiting[*]:+waiting ${waiting[*]}}${waiting[*]:+${running[*]:+, }}${running[*]:+running ${running[*]}}"
            for id in "${waiting[@]}" "${running[@]}"; do acts+=("gh run cancel ${id} -R ${slug}   (owner)"); done
            acts+=("(owner; waiting runs first. gh run cancel returns before the run stops:"
                   " run make release-abandon-status VERSION=${version} again until runs PASS)")
            next_lines "${acts[@]}"
            FAILURES+=1
            return
        fi
        stage PASS runs "every release run completed"
    fi

    # Stage 2: local. The checkout must hold no release change and match
    # origin/master, so that the master stage reads the remote state.
    mapfile -t dirty < <(git -C "$SC_TOP" status --porcelain)
    if printf "%s\n" "${dirty[@]}" | grep -q ' configure/VERSIONS$'; then
        stage FAIL local "configure/VERSIONS has an uncommitted change"
        next_lines "git -C ${SC_TOP} status --short   (agent shows it to the owner)" \
            "git -C ${SC_TOP} restore configure/VERSIONS   (agent, after the owner confirms)"
        FAILURES+=1
        return
    fi
    origin="$(git -C "$SC_TOP" ls-remote origin refs/heads/master 2> /dev/null | cut -f1)"
    [[ -n "$origin" ]] || { stage FAIL local "cannot read origin/master"; FAILURES+=1; return; }
    if ! git -C "$SC_TOP" cat-file -e "${origin}^{commit}" 2> /dev/null; then
        stage FAIL local "origin/master ${origin:0:7} is not in the local clone"
        next_lines "git -C ${SC_TOP} fetch   (agent), then run make release-abandon-status VERSION=${version} again"
        FAILURES+=1
        return
    fi
    head="$(git -C "$SC_TOP" rev-parse HEAD)"
    read -r ahead behind < <(git -C "$SC_TOP" rev-list --left-right --count "${head}...${origin}")
    if (( ahead > 0 )); then
        mapfile -t local_commits < <(git -C "$SC_TOP" log --oneline "${origin}..${head}")
        if [[ "$(image_version_at "$origin")" == "$version" && "$(image_version_at "$head")" != "$version" ]]; then
            stage FAIL local "${ahead} local commit(s) take the release out of origin/master, not pushed"
            for line in "${local_commits[@]}"; do printf "      %s\n" "$line"; done
            if (( behind > 0 )); then
                next_lines "git -C ${SC_TOP} rebase origin/master   (owner, when the listed commits are the reverts of the release;" \
                    "  origin/master moved by ${behind} commit(s) since they were made)" \
                    "git -C ${SC_TOP} push   (owner)" \
                    "stop and ask the owner when a listed commit is other work   (agent)"
            else
                next_lines "git -C ${SC_TOP} push   (owner, when the listed commits are the reverts of the release)" \
                    "stop and ask the owner when a listed commit is other work   (agent)"
            fi
        else
            stage FAIL local "${ahead} local commit(s) not on origin/master"
            for line in "${local_commits[@]}"; do printf "      %s\n" "$line"; done
            next_lines "git -C ${SC_TOP} reset --keep origin/master   (owner, when every listed commit belongs to the release)" \
                "stop and ask the owner when a listed commit is other work   (agent)"
        fi
        FAILURES+=1
        return
    elif (( behind > 0 )); then
        stage FAIL local "HEAD is ${behind} commit(s) behind origin/master"
        next_lines "git -C ${SC_TOP} merge --ff-only origin/master   (owner)"
        FAILURES+=1
        return
    fi
    stage PASS local "HEAD ${head:0:7} = origin/master${dirty[*]:+; other uncommitted paths left as they are}"

    # Stage 3: master. While origin/master has IMAGE_VERSION=<version>, the
    # release commit is the newest commit whose change touches that line and
    # whose tree still has it; the previous version is the value before it.
    if [[ "$(image_version_at "$origin")" == "$version" ]]; then
        rel=""
        while IFS= read -r line; do
            [[ "$(image_version_at "$line")" == "$version" ]] && { rel="$line"; break; }
        done < <(git -C "$SC_TOP" log --format=%H -S"IMAGE_VERSION=${version}" "$origin" -- configure/VERSIONS)
        [[ -n "$rel" ]] || die "cannot find the commit that set IMAGE_VERSION=${version}"
        prev="$(image_version_at "${rel}^")"
        [[ -n "$prev" ]] || die "commit ${rel:0:7}^ has no IMAGE_VERSION; the release commit also added configure/VERSIONS"
        mapfile -t list < <(git -C "$SC_TOP" log --oneline "${rel}^..${origin}")
        stage FAIL master "origin/master has IMAGE_VERSION=${version}; release commit ${rel:0:7}, previous ${prev}"
        for line in "${list[@]}"; do printf "      %s\n" "$line"; done
        next_lines "git -C ${SC_TOP} revert --no-edit ${rel:0:12}^..origin/master   (owner, when every listed commit belongs to the release)" \
            "git -C ${SC_TOP} revert --no-edit <commit>   (owner, otherwise: one per release commit, newest first)" \
            "git -C ${SC_TOP} push   (owner), then run make release-abandon-status VERSION=${version} again"
        FAILURES+=1
        return
    fi
    prev="$(image_version_at "$origin")"
    [[ -n "$prev" ]] || die "origin/master has no configure/VERSIONS"
    stage PASS master "origin/master has IMAGE_VERSION=${prev}, the previous version"

    # Stage 4: hub. latest returns to the previous version first; then the
    # <version> tag goes, so a later release.yml run does not skip the image.
    acts=()
    for dir in "${dirs[@]}"; do
        repo="$(envconf_value "${SC_TOP}/${dir}/env.conf" DOCKER_ID)/$(envconf_value "${SC_TOP}/${dir}/env.conf" TARGET_NAME)"
        if ! want="$(hub_digest "$repo" "$prev")" || ! digest="$(hub_digest "$repo" latest)"; then
            acts+=("run make release-abandon-status VERSION=${version} again once Docker Hub answers (agent; ${repo} unreadable)")
            continue
        fi
        [[ -n "$want" ]] || die "${repo}:${prev} does not exist; latest has no previous tag to return to"
        if [[ "$digest" != "$want" ]]; then
            acts+=("docker buildx imagetools create -t ${repo}:latest ${repo}:${prev}   (owner, docker login)")
        fi
        if ! digest="$(hub_digest "$repo" "$version")"; then
            acts+=("run make release-abandon-status VERSION=${version} again once Docker Hub answers (agent; ${repo} unreadable)")
        elif [[ -n "$digest" ]]; then
            acts+=("delete tag ${version} at https://hub.docker.com/r/${repo}/tags   (owner, after latest is back)")
        fi
    done
    if (( ${#acts[@]} > 0 )); then
        stage FAIL hub "$(printf "%d action(s) remain" "${#acts[@]}")"
        next_lines "${acts[@]}" "then run make release-abandon-status VERSION=${version} again   (agent)"
        FAILURES+=1
        return
    fi
    stage PASS hub "${#dirs[@]}/${#dirs[@]} latest = ${prev}, no ${version} tag"
    printf "Abandon: done (%s abandoned; latest = %s)\n" "$version" "$prev"
}

function main {
    case "${1:-}" in
        check)      (( $# == 2 )) || usage; release_check "$2" ;;
        components) (( $# == 1 )) || usage; release_components ;;
        status)     (( $# == 2 )) || usage; release_status "$2" ;;
        verify)     (( $# == 2 )) || usage; release_verify "$2" ;;
        abandon)    (( $# == 2 )) || usage; release_abandon "$2" ;;
        *)          usage ;;
    esac
    (( FAILURES == 0 ))
}

main "$@"
