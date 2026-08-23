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
assert_contains "$help_output" "--skip-apimanac"
assert_contains "$help_output" "Fetch APImanac skill/SKILL.md from GitHub"

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
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" bash "$ROOT/scripts/install.sh" \
    --dry-run \
    --skip-skills \
    --skip-claude \
    --skip-pi \
    --skip-opencode \
    --skip-kilo \
    --skip-cursor \
    --skip-prompts
)"
assert_contains "$codex_output" \
  "Symlink: $test_home/.codex/notify-dispatch.sh -> $ROOT/codex/notify-dispatch.sh"
assert_contains "$codex_output" \
  "DRY-RUN: fetch https://raw.githubusercontent.com/stanfish06/APImanac/master/skill/SKILL.md -> $ROOT/apis/SKILL.md"
assert_contains "$codex_output" \
  "Symlink: $test_home/.codex/skills/apimanac/SKILL.md -> $ROOT/apis/SKILL.md"
assert_not_contains "$codex_output" \
  "$test_home/.claude/skills/apimanac"

pi_kilo_output="$(
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" bash "$ROOT/scripts/install.sh" \
    --dry-run \
    --skip-skills \
    --skip-claude \
    --skip-codex \
    --skip-opencode \
    --skip-cursor \
    --skip-prompts
)"
assert_contains "$pi_kilo_output" \
  "Symlink: $test_home/.pi/agent/AGENTS.md -> $ROOT/pi-agent/AGENTS.md"
assert_contains "$pi_kilo_output" \
  "Symlink: $test_home/.config/kilo/AGENTS.md -> $ROOT/kilo/AGENTS.md"
assert_contains "$pi_kilo_output" \
  "Symlink: $test_home/.pi/agent/skills/apimanac/SKILL.md -> $ROOT/apis/SKILL.md"
assert_contains "$pi_kilo_output" \
  "Symlink: $test_home/.kilo/skills/apimanac/SKILL.md -> $ROOT/apis/SKILL.md"

cursor_output="$(
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" bash "$ROOT/scripts/install.sh" \
    --dry-run \
    --skip-skills \
    --skip-claude \
    --skip-codex \
    --skip-pi \
    --skip-opencode \
    --skip-kilo \
    --skip-prompts
)"
assert_contains "$cursor_output" \
  "Symlink: $test_home/.cursor/rules/behaviors.mdc -> $ROOT/cursor/rules/behaviors.mdc"
assert_contains "$cursor_output" \
  "Symlink: $test_home/.cursor/rules/dev.mdc -> $ROOT/cursor/rules/dev.mdc"
assert_contains "$cursor_output" \
  "Symlink: $test_home/.cursor/rules/skills.mdc -> $ROOT/cursor/rules/skills.mdc"
assert_contains "$cursor_output" \
  "Symlink: $test_home/.cursor/rules/context-hygiene.mdc -> $ROOT/cursor/rules/context-hygiene.mdc"
assert_contains "$cursor_output" \
  "Copy: $ROOT/cursor/cli-config.json -> $test_home/.cursor/cli-config.json"
assert_contains "$cursor_output" \
  "Symlink: $test_home/.cursor/skills/apimanac/SKILL.md -> $ROOT/apis/SKILL.md"

skip_apimanac_output="$(
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" bash "$ROOT/scripts/install.sh" \
    --dry-run \
    --skip-skills \
    --skip-prompts \
    --skip-apimanac
)"
assert_contains "$skip_apimanac_output" "Skip: APImanac"
assert_not_contains "$skip_apimanac_output" "skills/apimanac"
assert_not_contains "$skip_apimanac_output" "DRY-RUN: fetch"

skill_backup="$(mktemp)"
fake_skill="$(mktemp)"
cp "$ROOT/apis/SKILL.md" "$skill_backup"
restore_skill() {
  cp "$skill_backup" "$ROOT/apis/SKILL.md"
  rm -f "$skill_backup" "$fake_skill"
  rm -rf "$test_home"
}
trap restore_skill EXIT
cat > "$fake_skill" <<'EOF'
---
name: apimanac
description: installer refresh fixture
---
# fixture
EOF
refresh_output="$(
  HOME="$test_home" XDG_CONFIG_HOME="$test_home/.config" \
  APIMANAC_SKILL_URL="file://${fake_skill}" \
  bash "$ROOT/scripts/install.sh" \
    --skip-skills \
    --skip-claude \
    --skip-codex \
    --skip-pi \
    --skip-opencode \
    --skip-kilo \
    --skip-cursor \
    --skip-prompts
)"
assert_contains "$refresh_output" "Refresh: file://${fake_skill} -> $ROOT/apis/SKILL.md"
cmp -s "$fake_skill" "$ROOT/apis/SKILL.md" || fail "apis/SKILL.md was not refreshed from APIMANAC_SKILL_URL"
cp "$skill_backup" "$ROOT/apis/SKILL.md"

cursor_config="$(<"$ROOT/cursor/cli-config.json")"
assert_contains "$cursor_config" '"approvalMode": "unrestricted"'
assert_not_contains "$cursor_config" "authInfo"
assert_not_contains "$cursor_config" "authCacheKey"
assert_not_contains "$cursor_config" "privacyCache"

bash "$ROOT/scripts/test-amux-hooks.sh"

echo "PASS: scripts/install.sh extras and Codex notifier wiring"
