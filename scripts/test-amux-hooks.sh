#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASH_BIN="$(command -v bash)"
NODE_BIN="$(command -v node)"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
fake_bin="$tmp_dir/bin"
event_log="$tmp_dir/events.log"
stdin_log="$tmp_dir/stdin.log"
mkdir -p "$fake_bin"
ln -s "$(command -v basename)" "$fake_bin/basename"
ln -s "$BASH_BIN" "$fake_bin/bash"

missing_output="$(
  HOME="$tmp_dir/missing-home" \
  TMUX="/tmp/amux-root-1000,1,0" \
  TMUX_PANE="%1" \
  PATH="$fake_bin" \
  "$BASH_BIN" "$ROOT/hooks/amux-event.sh" busy codex
)"
[[ -z "$missing_output" ]] || fail "missing amux produced output"
[[ ! -e "$event_log" ]] || fail "missing amux emitted an event"

# the fake amux runs with PATH="$fake_bin", so bake in absolute tool paths
bash_bin="$(command -v bash)"
cat_bin="$(command -v cat)"
cat > "$fake_bin/amux" <<SH
#!${bash_bin}
printf '%s\\n' "\$*" >> "\${AMUX_TEST_LOG:?}"
${cat_bin} > "\${AMUX_TEST_STDIN_LOG:?}"
SH
chmod +x "$fake_bin/amux"

HOME="$tmp_dir/home" \
TMUX="/tmp/ordinary,1,0" \
TMUX_PANE="%1" \
PATH="$fake_bin" \
AMUX_TEST_LOG="$event_log" \
AMUX_TEST_STDIN_LOG="$stdin_log" \
"$BASH_BIN" "$ROOT/hooks/amux-event.sh" busy codex
[[ ! -e "$event_log" ]] || fail "non-amux tmux pane emitted an event"

payload='{"hook_event_name":"UserPromptSubmit"}'
printf '%s' "$payload" | \
  HOME="$tmp_dir/home" \
  TMUX="/tmp/amux-root-1000,1,0" \
  TMUX_PANE="%42" \
  PATH="$fake_bin" \
  AMUX_TEST_LOG="$event_log" \
  AMUX_TEST_STDIN_LOG="$stdin_log" \
  "$BASH_BIN" "$ROOT/hooks/amux-event.sh" busy codex
grep -Fqx 'event emit busy --agent codex' "$event_log" ||
  fail "amux pane did not emit busy codex"
[[ "$(<"$stdin_log")" == "$payload" ]] || fail "hook payload was not forwarded"

"$NODE_BIN" - "$ROOT/codex/hooks.json" <<'NODE'
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const commands = event => (config.hooks[event] || [])
  .flatMap(group => group.hooks || [])
  .map(handler => handler.command);
if (!commands('UserPromptSubmit').includes(
  'bash ~/.codex/hooks/dot-agents/amux-event.sh busy codex')) {
  throw new Error('missing Codex UserPromptSubmit → amux busy hook');
}
if (!commands('PreToolUse').includes(
  'bash ~/.codex/hooks/dot-agents/amux-event.sh busy codex')) {
  throw new Error('missing Codex PreToolUse → amux busy hook');
}
if (!commands('PermissionRequest').includes(
  'bash ~/.codex/hooks/dot-agents/amux-event.sh notify codex')) {
  throw new Error('missing Codex PermissionRequest → amux notify hook');
}
if (!commands('SessionEnd').includes(
  'bash ~/.codex/hooks/dot-agents/amux-event.sh exit codex')) {
  throw new Error('missing Codex SessionEnd → amux exit hook');
}
NODE

: > "$event_log"
test_home="$tmp_dir/dispatcher-home"
mkdir -p "$test_home/.codex/hooks/dot-agents"
ln -s "$ROOT/hooks/amux-event.sh" \
  "$test_home/.codex/hooks/dot-agents/amux-event.sh"

HOME="$test_home" \
TMUX="/tmp/amux-root-1000,1,0" \
TMUX_PANE="%42" \
PATH="$fake_bin" \
AMUX_TEST_LOG="$event_log" \
AMUX_TEST_STDIN_LOG="$stdin_log" \
"$BASH_BIN" "$ROOT/codex/notify-dispatch.sh" \
  '{"type":"agent-turn-complete"}'

for _ in {1..100}; do
  grep -Fqx 'event emit stop --agent codex' "$event_log" && break
  sleep 0.01
done
grep -Fqx 'event emit stop --agent codex' "$event_log" ||
  fail "Codex notify dispatcher did not emit stop codex"

echo "PASS: Codex amux hooks and fallback behavior"
