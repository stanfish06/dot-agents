#!/usr/bin/env bash
# Emits an amux agent-state event from an agent lifecycle hook, so the pane's
# roster state (busy/idle/needs-input/dead) stays live in `amux ctx`.
#
#   amux-event.sh <spawn|busy|stop|notify|exit> [agent]
#
# amux is optional on any given machine, and most sessions don't run inside an
# amux pane at all: outside the amux tmux server (socket name `amux-root`) or
# without the binary, this is a silent no-op rather than a failing hook on
# every turn. Hook JSON arrives on stdin and `amux event emit` reads it for
# the event detail (notification message, tool name, exit reason), hence the
# `exec` -- the payload has to survive the handoff.
set -uo pipefail

kind="${1:?usage: amux-event.sh <kind> [agent]}"
agent="${2:-claude}"

# Cheap pre-checks: skip the (PyInstaller, slow-to-start) binary entirely
# unless this pane lives on an amux socket. $TMUX is "socketpath,pid,session".
[ -n "${TMUX_PANE:-}" ] || exit 0
case "$(basename "${TMUX%%,*}" 2>/dev/null)" in
  amux-root*) ;;
  *) exit 0 ;;
esac

amux_bin="$(command -v amux || true)"
[ -n "$amux_bin" ] || amux_bin="$HOME/.local/bin/amux"
[ -x "$amux_bin" ] || exit 0

exec "$amux_bin" event emit "$kind" --agent "$agent"
