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

assert_not_contains() {
  local output="$1"
  local unexpected="$2"

  [[ "$output" != *"$unexpected"* ]] ||
    fail "expected output not to contain: $unexpected"
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

config_text="$(<"$ROOT/codex/config.toml")"
expected_notify="notify = [\"/bin/sh\", \"-c\", 'exec \"\$HOME/.codex/notify-dispatch.sh\" \"\$@\"', \"codex-notify\"]"
assert_contains "$config_text" "$expected_notify"
assert_not_contains "$config_text" "/Users/stan/Git/dot-agents/codex/notify-dispatch.sh"

dispatcher_text="$(<"$ROOT/codex/notify-dispatch.sh")"
assert_contains "$dispatcher_text" \
  "nvim_notify=\"\$HOME/.codex/hooks/dot-agents/nvim-notify.sh\""
assert_not_contains "$dispatcher_text" $'\nwait\n'

test_home="$(mktemp -d)"
trap 'rmdir "$test_home"' EXIT
codex_output="$(
  HOME="$test_home" bash "$ROOT/scripts/install.sh" \
    --dry-run \
    --skip-skills \
    --skip-claude \
    --skip-pi \
    --skip-opencode \
    --skip-kilo \
    --skip-prompts
)"
assert_contains "$codex_output" \
  "Symlink: $test_home/.codex/notify-dispatch.sh -> $ROOT/codex/notify-dispatch.sh"

echo "PASS: scripts/install.sh extras and Codex notifier wiring"
