#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local output="$1"
  local expected="$2"

  [[ "$output" == *"$expected"* ]] ||
    fail "expected output to contain: $expected"
}

help_output="$(bash "$ROOT/scripts/install.sh" --help)"
assert_contains "$help_output" "--extras <name>..."
assert_contains "$help_output" "Names: gstack, career (alias: career-ops), all"

list_output="$(bash "$ROOT/scripts/install.sh" --dry-run --skip-config --extras gstack career)"
assert_contains "$list_output" \
  "DRY-RUN: bash $ROOT/skills/install-skills.sh --extras gstack career"

csv_output="$(bash "$ROOT/scripts/install.sh" --dry-run --skip-config --extras=gstack,career-ops)"
assert_contains "$csv_output" \
  "DRY-RUN: bash $ROOT/skills/install-skills.sh --extras gstack career"

set +e
bad_output="$(bash "$ROOT/scripts/install.sh" --dry-run --skip-config --extras nope 2>&1)"
bad_status=$?
set -e

[ "$bad_status" -ne 0 ] || fail "unknown extra unexpectedly succeeded"
assert_contains "$bad_output" "unknown extra 'nope'"

echo "PASS: scripts/install.sh extras parsing and forwarding"
