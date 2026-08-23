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
SKIP_OPENCODE=0
SKIP_KILO=0
SKIP_CURSOR=0
SKIP_PROMPTS=0
FORCE=0
ALLOW_DIRTY_SKILLS=0
EXTRA_GSTACK=0
EXTRA_CAREER=0

die() {
  echo "ERROR: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: scripts/install.sh [options]

Install this dot-agents checkout into the current user's agent homes.

Options:
  --dry-run             Print actions without changing files.
  --skip-skills         Do not run skills/install-skills.sh.
  --skip-config         Do not symlink Claude/Codex/Pi/opencode/Kilo/Cursor config.
  --skip-claude         Do not symlink Claude config.
  --skip-codex          Do not symlink Codex config.
  --skip-pi             Do not symlink Pi agent config.
  --skip-opencode       Do not symlink opencode config.
  --skip-kilo           Do not symlink Kilo Code config.
  --skip-cursor         Do not symlink Cursor user rules.
  --skip-prompts        Do not install prompts/live-prompts/*.md.
  --extras <name>...    Install optional skill extras.
                        Names: gstack, career (alias: career-ops), all
  --extras=<csv>        Comma-separated form (e.g. --extras=gstack,career).
  --force               Replace existing non-matching targets without backups.
  --allow-dirty-skills  Run skills/install-skills.sh even if the submodule is dirty.
  -h, --help            Show this help.

Default behavior:
  - Initialize the skills submodule.
  - Run skills/install-skills.sh, which delegates skill installation to Vercel's
    skills CLI and installs graphify. gstack and career-ops are skipped unless
    selected with --extras.
  - Symlink selected Claude, Codex, Pi, opencode, Kilo Code, and Cursor
    config paths into their agent homes.
  - Install live prompts into each agent's native prompt/command surface.
  - Move any existing non-matching target to TARGET.backup-<timestamp>.
EOF
}

enable_extra() {
  local name="${1//[[:space:]]/}"

  [ -n "$name" ] || return 0
  case "$name" in
    gstack) EXTRA_GSTACK=1 ;;
    career|career-ops) EXTRA_CAREER=1 ;;
    all)
      EXTRA_GSTACK=1
      EXTRA_CAREER=1
      ;;
    *) die "unknown extra '$name' (expected: gstack, career, all)" ;;
  esac
}

enable_extras_csv() {
  local csv="${1//,/ }"
  local name

  # shellcheck disable=SC2086
  for name in $csv; do
    enable_extra "$name"
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-skills) SKIP_SKILLS=1 ;;
    --skip-config) SKIP_CONFIG=1 ;;
    --skip-claude) SKIP_CLAUDE=1 ;;
    --skip-codex) SKIP_CODEX=1 ;;
    --skip-pi) SKIP_PI=1 ;;
    --skip-opencode) SKIP_OPENCODE=1 ;;
    --skip-kilo) SKIP_KILO=1 ;;
    --skip-cursor) SKIP_CURSOR=1 ;;
    --skip-prompts) SKIP_PROMPTS=1 ;;
    --extras)
      shift
      if [ "$#" -eq 0 ] || [[ "$1" == -* ]]; then
        die "--extras requires at least one name (gstack, career, all)"
      fi
      while [ "$#" -gt 0 ] && [[ "$1" != -* ]]; do
        enable_extras_csv "$1"
        shift
      done
      continue
      ;;
    --extras=*)
      value="${1#--extras=}"
      [ -n "$value" ] ||
        die "--extras= requires at least one name (gstack, career, all)"
      enable_extras_csv "$value"
      ;;
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

install_copy() {
  local source="$1"
  local target="$2"

  [ -f "$source" ] && [ ! -L "$source" ] ||
    die "copy source must be a regular file: $source"
  ensure_parent_dir "$target"

  if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$source" "$target"; then
    log "OK: $target matches $source"
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

  log "Copy: $source -> $target"
  run cp "$source" "$target"
}

ensure_real_dir() {
  local target="$1"

  if [ -d "$target" ] && [ ! -L "$target" ]; then
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

  log "Directory: $target"
  run mkdir -p "$target"
}

install_live_prompts() {
  local agent="$1"
  local target_dir="$2"
  local source_dir="$ROOT/prompts/live-prompts"
  local found=0
  local source

  if [ ! -d "$source_dir" ]; then
    log "Skip: $agent live prompts (missing $source_dir)"
    return 0
  fi

  for source in "$source_dir"/*.md; do
    [ -e "$source" ] || continue
    found=1
    install_link "$source" "$target_dir/$(basename "$source")"
  done

  if [ "$found" -eq 0 ]; then
    log "Skip: $agent live prompts (no .md files)"
  fi
}

skills_tree_dirty() {
  ! git -C "$ROOT/skills" diff --quiet ||
    ! git -C "$ROOT/skills" diff --cached --quiet ||
    [ -n "$(git -C "$ROOT/skills" status --short --untracked-files=all)" ]
}

install_skills() {
  local install_args=()

  if [ "$EXTRA_GSTACK" -eq 1 ] || [ "$EXTRA_CAREER" -eq 1 ]; then
    install_args+=(--extras)
    [ "$EXTRA_GSTACK" -eq 0 ] || install_args+=(gstack)
    [ "$EXTRA_CAREER" -eq 0 ] || install_args+=(career)
  fi

  log "==> Skills"
  run git -C "$ROOT" submodule update --init --recursive skills

  if [ "$DRY_RUN" -eq 1 ]; then
    run bash "$ROOT/skills/install-skills.sh" "${install_args[@]}"
    return 0
  fi

  if skills_tree_dirty && [ "$ALLOW_DIRTY_SKILLS" -ne 1 ]; then
    die "skills submodule has uncommitted changes; commit/stash them or rerun with --skip-skills/--allow-dirty-skills"
  fi

  bash "$ROOT/skills/install-skills.sh" "${install_args[@]}"
}

install_claude() {
  log "==> Claude"
  install_link "$ROOT/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  install_link "$ROOT/claude/settings.json" "$HOME/.claude/settings.json"
  install_link "$ROOT/claude/settings.local.json" "$HOME/.claude/settings.local.json"
  install_link "$ROOT/claude/commands/agent-skills" "$HOME/.claude/commands/agent-skills"
  install_link "$ROOT/claude/skills/graphify" "$HOME/.claude/skills/graphify"
  install_link "$ROOT/hooks" "$HOME/.claude/hooks/dot-agents"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_live_prompts "Claude" "$HOME/.claude/commands"
  fi

  install_link "$ROOT/agents/code-reviewer.md" "$HOME/.claude/agents/code-reviewer.md"
  install_link "$ROOT/agents/security-auditor.md" "$HOME/.claude/agents/security-auditor.md"
  install_link "$ROOT/agents/test-engineer.md" "$HOME/.claude/agents/test-engineer.md"
  install_link "$ROOT/agents/web-performance-auditor.md" "$HOME/.claude/agents/web-performance-auditor.md"
}

install_codex() {
  log "==> Codex"
  install_link "$ROOT/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
  install_link "$ROOT/codex/notify-dispatch.sh" "$HOME/.codex/notify-dispatch.sh"
  install_link "$ROOT/codex/config.toml" "$HOME/.codex/config.toml"
  install_link "$ROOT/codex/hooks.json" "$HOME/.codex/hooks.json"
  install_link "$ROOT/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
  install_link "$ROOT/codex/skills/hatch-pet" "$HOME/.codex/skills/hatch-pet"
  install_link "$ROOT/hooks" "$HOME/.codex/hooks/dot-agents"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_codex_skill_prompts
  fi
}

install_codex_skill_prompts() {
  local prompt_dir="$ROOT/prompts/live-prompts"
  local skills_dir="$HOME/.codex/skills"
  local found=0
  local source stem target_dir

  if [ ! -d "$prompt_dir" ]; then
    log "Skip: Codex live prompts (missing $prompt_dir)"
    return 0
  fi

  for source in "$prompt_dir"/*.md; do
    [ -e "$source" ] || continue
    found=1
    stem="$(basename "$source" .md)"
    target_dir="$skills_dir/$stem"
    ensure_real_dir "$target_dir"
    install_copy "$source" "$target_dir/SKILL.md"
  done

  if [ "$found" -eq 0 ]; then
    log "Skip: Codex live prompts (no .md files)"
  fi
}

install_pi() {
  log "==> Pi"
  install_link "$ROOT/pi-agent/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
  install_link "$ROOT/pi-agent/themes/mypi.json" "$HOME/.pi/agent/themes/mypi.json"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_live_prompts "Pi" "$HOME/.pi/agent/prompts"
  fi
}

install_opencode() {
  log "==> opencode"
  install_link "$ROOT/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  install_link "$ROOT/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
  install_link "$ROOT/opencode/tui.json" "$HOME/.config/opencode/tui.json"
  install_link "$ROOT/opencode/themes/mypi.json" "$HOME/.config/opencode/themes/mypi.json"
  install_link "$ROOT/agents/code-reviewer.md" "$HOME/.config/opencode/agent/code-reviewer.md"
  install_link "$ROOT/agents/security-auditor.md" "$HOME/.config/opencode/agent/security-auditor.md"
  install_link "$ROOT/agents/test-engineer.md" "$HOME/.config/opencode/agent/test-engineer.md"
  install_link "$ROOT/agents/web-performance-auditor.md" "$HOME/.config/opencode/agent/web-performance-auditor.md"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_live_prompts "opencode" "$HOME/.config/opencode/command"
  fi
}

install_kilo() {
  log "==> Kilo Code"
  install_link "$ROOT/kilo/AGENTS.md" "$HOME/.config/kilo/AGENTS.md"
  install_link "$ROOT/kilo/kilo.jsonc" "$HOME/.config/kilo/kilo.jsonc"
}

install_cursor() {
  local source_dir="$ROOT/cursor/rules"
  local target_dir="$HOME/.cursor/rules"
  local source
  local found=0

  log "==> Cursor"
  [ -d "$source_dir" ] || die "missing Cursor rules directory: $source_dir"

  for source in "$source_dir"/*.mdc; do
    [ -e "$source" ] || continue
    found=1
    install_link "$source" "$target_dir/$(basename "$source")"
  done

  [ "$found" -eq 1 ] || die "missing Cursor rules in $source_dir"
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

  if [ "$SKIP_OPENCODE" -eq 0 ]; then
    install_opencode
  else
    log "Skip: opencode"
  fi

  if [ "$SKIP_KILO" -eq 0 ]; then
    install_kilo
  else
    log "Skip: Kilo Code"
  fi

  if [ "$SKIP_CURSOR" -eq 0 ]; then
    install_cursor
  else
    log "Skip: Cursor"
  fi
}

main
