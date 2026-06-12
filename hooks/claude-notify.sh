#!/usr/bin/env bash
set -euo pipefail

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

notify "claude-code" "Claude Code" "Claude Code needs your attention"
