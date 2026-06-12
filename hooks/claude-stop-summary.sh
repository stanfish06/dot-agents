#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"

json_get() {
  local filter="$1"
  printf '%s' "$INPUT" | jq -r "$filter // empty" 2>/dev/null || true
}

notify() {
  local app="$1"
  local title="$2"
  local message="$3"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "$app" "$title" "$message" >/dev/null 2>&1 || true
    return 0
  fi

  if command -v osascript >/dev/null 2>&1; then
    NOTIFY_TITLE="$title" NOTIFY_MESSAGE="$message" osascript >/dev/null 2>&1 <<'OSA' || true
display notification (system attribute "NOTIFY_MESSAGE") with title (system attribute "NOTIFY_TITLE")
OSA
  fi
}

run_claude_summary() {
  local prompt="$1"

  if ! command -v claude >/dev/null 2>&1; then
    return 0
  fi

  if command -v timeout >/dev/null 2>&1; then
    timeout 45s claude -p --model "haiku" "$prompt" 2>/dev/null || true
  else
    claude -p --model "haiku" "$prompt" 2>/dev/null || true
  fi
}

transcript="$(json_get '.transcript_path')"
[ -n "$transcript" ] || transcript="$(json_get '.transcriptPath')"
[ -n "$transcript" ] || transcript="$(json_get '.session.transcript_path')"

last_msg="$(json_get '.last_assistant_message')"
[ -n "$last_msg" ] || last_msg="$(json_get '.lastAssistantMessage')"
[ -n "$last_msg" ] || last_msg="$(json_get '.session.last_assistant_message')"

summary=""
if [ "${DOT_AGENTS_STOP_SUMMARY_WITH_CLAUDE:-0}" = "1" ]; then
  prompt="Here is the last assistant message: ${last_msg}. The transcript is at ${transcript}. Based on the last message and relevant parts of the transcript, give me a short summary: when it finished, how long it took, success or fail, major changes, and what is next. Cap summary at 10-15 words. Reply in one human-readable sentence, not markdown."
  summary="$(run_claude_summary "$prompt")"
fi

[ -n "$summary" ] || summary="$last_msg"
[ -n "$summary" ] || summary="summary unavailable"

notify "claude-code" "Claude Code" "Claude Code stopped: ${summary}"
