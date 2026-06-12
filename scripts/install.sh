#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

DRY_RUN=0
SKIP_SKILLS=0
SKIP_CONFIG=0
SKIP_CLAUDE=0
SKIP_CODEX=0
SKIP_PI=0
FORCE=0
ALLOW_DIRTY_SKILLS=0

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [options]

Install this dot-agents checkout into the current user's agent homes.

Options:
  --dry-run             Print actions without changing files.
  --skip-skills         Do not run skills/install-skills.sh.
  --skip-config         Do not symlink Claude/Codex/Pi config.
  --skip-claude         Do not symlink Claude config.
  --skip-codex          Do not symlink Codex config.
  --skip-pi             Do not symlink Pi agent config.
  --force               Replace existing non-matching targets without backups.
  --allow-dirty-skills  Run skills/install-skills.sh even if the submodule is dirty.
  -h, --help            Show this help.

Default behavior:
  - Initialize the skills submodule.
  - Run skills/install-skills.sh, which delegates skill installation to Vercel's
    skills CLI and installs graphify.
  - Symlink selected Claude, Codex, and Pi config paths into their agent homes.
  - Move any existing non-matching target to TARGET.backup-<timestamp>.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-skills) SKIP_SKILLS=1 ;;
    --skip-config) SKIP_CONFIG=1 ;;
    --skip-claude) SKIP_CLAUDE=1 ;;
    --skip-codex) SKIP_CODEX=1 ;;
    --skip-pi) SKIP_PI=1 ;;
    --force) FORCE=1 ;;
    --allow-dirty-skills) ALLOW_DIRTY_SKILLS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

log() {
  printf '%s\n' "$*"
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

backup_name_for() {
  local target="$1"
  local base="${target}.backup-${TIMESTAMP}"
  local candidate="$base"
  local n=1

  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    candidate="${base}-${n}"
    n=$((n + 1))
  done
  printf '%s\n' "$candidate"
}

ensure_parent_dir() {
  local target="$1"
  local parent
  parent="$(dirname "$target")"
  [ -d "$parent" ] || run mkdir -p "$parent"
}

install_link() {
  local source="$1"
  local target="$2"

  [ -e "$source" ] || [ -L "$source" ] || die "missing source: $source"
  ensure_parent_dir "$target"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    log "OK: $target -> $source"
    return 0
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "Replace: $target"
      run rm -rf "$target"
    else
      local backup
      backup="$(backup_name_for "$target")"
      log "Backup: $target -> $backup"
      run mv "$target" "$backup"
    fi
  fi

  log "Symlink: $target -> $source"
  run ln -s "$source" "$target"
}

skills_tree_dirty() {
  ! git -C "$ROOT/skills" diff --quiet ||
    ! git -C "$ROOT/skills" diff --cached --quiet ||
    [ -n "$(git -C "$ROOT/skills" status --short --untracked-files=all)" ]
}

install_skills() {
  log "==> Skills"
  run git -C "$ROOT" submodule update --init --recursive skills

  if [ "$DRY_RUN" -eq 1 ]; then
    run bash "$ROOT/skills/install-skills.sh"
    return 0
  fi

  if skills_tree_dirty && [ "$ALLOW_DIRTY_SKILLS" -ne 1 ]; then
    die "skills submodule has uncommitted changes; commit/stash them or rerun with --skip-skills/--allow-dirty-skills"
  fi

  bash "$ROOT/skills/install-skills.sh"
}

install_claude() {
  log "==> Claude"
  install_link "$ROOT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  install_link "$ROOT/claude/settings.json" "$HOME/.claude/settings.json"
  install_link "$ROOT/claude/settings.local.json" "$HOME/.claude/settings.local.json"
  install_link "$ROOT/claude/commands/agent-skills" "$HOME/.claude/commands/agent-skills"
  install_link "$ROOT/claude/skills/graphify" "$HOME/.claude/skills/graphify"
  install_link "$ROOT/hooks" "$HOME/.claude/hooks/dot-agents"

  install_link "$ROOT/agents/code-reviewer.md" "$HOME/.claude/agents/code-reviewer.md"
  install_link "$ROOT/agents/security-auditor.md" "$HOME/.claude/agents/security-auditor.md"
  install_link "$ROOT/agents/test-engineer.md" "$HOME/.claude/agents/test-engineer.md"
  install_link "$ROOT/agents/web-performance-auditor.md" "$HOME/.claude/agents/web-performance-auditor.md"
}

install_codex() {
  log "==> Codex"
  install_link "$ROOT/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  install_link "$ROOT/codex/config.toml" "$HOME/.codex/config.toml"
  install_link "$ROOT/codex/hooks.json" "$HOME/.codex/hooks.json"
  install_link "$ROOT/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
  install_link "$ROOT/codex/skills/hatch-pet" "$HOME/.codex/skills/hatch-pet"
  install_link "$ROOT/hooks" "$HOME/.codex/hooks/dot-agents"
}

install_pi() {
  log "==> Pi"
  install_link "$ROOT/pi-agent/themes/mypi.json" "$HOME/.pi/agent/themes/mypi.json"
}

main() {
  if [ "$SKIP_SKILLS" -eq 0 ]; then
    install_skills
  else
    log "Skip: skills"
  fi

  if [ "$SKIP_CONFIG" -eq 1 ]; then
    log "Skip: config"
    return 0
  fi

  if [ "$SKIP_CLAUDE" -eq 0 ]; then
    install_claude
  else
    log "Skip: Claude"
  fi

  if [ "$SKIP_CODEX" -eq 0 ]; then
    install_codex
  else
    log "Skip: Codex"
  fi

  if [ "$SKIP_PI" -eq 0 ]; then
    install_pi
  else
    log "Skip: Pi"
  fi
}

main
