#!/usr/bin/env bash
# Forwards an agent finish/attention event to the nvim notifier, so an agent
# running in a `:terminal` buffer says so on screen.
#
#   nvim-notify.sh <claude|codex> <stop|attention>
#
# The receiving half lives in the nvim config, not this repo, so treat it as
# optional: a machine without it gets a no-op rather than a failing hook on
# every turn. Hook JSON arrives on stdin and the notifier reads it, hence the
# `exec` -- the payload has to survive the handoff.
#
# Skipped for the nested `claude -p` that claude-stop-summary.sh spawns when
# DOT_AGENTS_STOP_SUMMARY_WITH_CLAUDE=1; that session fires Stop hooks of its
# own and would double every notification. Set DOT_AGENTS_NVIM_NOTIFY=0 to
# silence other scripted `claude -p` invocations the same way.
set -uo pipefail

[ "${DOT_AGENTS_NVIM_NOTIFY:-1}" = "0" ] && exit 0
[ "${DOT_AGENTS_STOP_SUMMARY_ACTIVE:-0}" = "1" ] && exit 0

target="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/scripts/agent-notify.sh"
[ -r "$target" ] || exit 0

exec bash "$target" "$@"
