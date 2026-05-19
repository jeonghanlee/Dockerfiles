#!/usr/bin/env bash

set -euo pipefail

readonly TRIGGER_DIR=".trigger"
readonly TRIGGER_FILE="${TRIGGER_DIR}/random"

mkdir -p "$TRIGGER_DIR"
printf "%08d\n" "$(((RANDOM * 32768 + RANDOM) % 100000000))" > "$TRIGGER_FILE"
