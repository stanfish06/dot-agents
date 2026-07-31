#!/usr/bin/env bash
# Codex allows exactly one `notify` program, so fan out from here:
#   1. the computer-use client this used to point at directly
#   2. the repo-managed nvim shim, which forwards to the in-editor notifier
#   3. the optional amux adapter, which marks this pane's turn as stopped
#
# Codex appends its event JSON as the final argument. Both legs are launched
# asynchronously, and failures are swallowed so notification cannot break a turn.
set -uo pipefail

sky="$HOME/.codex/computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient"
nvim_notify="$HOME/.codex/hooks/dot-agents/nvim-notify.sh"
amux_event="$HOME/.codex/hooks/dot-agents/amux-event.sh"

if [ -x "$sky" ]; then
    "$sky" turn-ended "$@" >/dev/null 2>&1 </dev/null &
fi

if [ -r "$nvim_notify" ]; then
    bash "$nvim_notify" codex stop "${1:-}" >/dev/null 2>&1 </dev/null &
fi

if [ -r "$amux_event" ]; then
    bash "$amux_event" stop codex >/dev/null 2>&1 </dev/null &
fi

exit 0
