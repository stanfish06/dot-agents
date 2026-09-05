#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
# Single source for every harness's global instructions file.
AGENTS_SRC="$ROOT/prompts/AGENTS.md"
# Per-harness config folders live under one directory.
HARNESSES="$ROOT/harnesses"

DRY_RUN=0
SKIP_SKILLS=0
SKIP_CONFIG=0
SKIP_CLAUDE=0
SKIP_CODEX=0
SKIP_PI=0
SKIP_OPENCODE=0
SKIP_KILO=0
SKIP_GROK=0
SKIP_CURSOR=0
SKIP_AGY=0
SKIP_APIMANAC=0
SKIP_PROMPTS=0
SKIP_TELEMETRY=0
FORCE=0
ALLOW_DIRTY_SKILLS=0
EXTRA_GSTACK=0
EXTRA_CAREER=0

# Upstream skill text. Override with APIMANAC_SKILL_URL to pin or test.
APIMANAC_SKILL_URL="${APIMANAC_SKILL_URL:-https://raw.githubusercontent.com/stanfish06/APImanac/master/skill/SKILL.md}"

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
  --skip-config         Do not symlink Claude/Codex/Pi/opencode/Kilo/Grok/Cursor config.
  --skip-claude         Do not symlink Claude config.
  --skip-codex          Do not symlink Codex config.
  --skip-pi             Do not symlink Pi agent config.
  --skip-opencode       Do not symlink opencode config.
  --skip-kilo           Do not symlink Kilo Code config.
  --skip-grok           Do not symlink Grok config.
  --skip-cursor         Do not install Cursor user rules or CLI config.
  --skip-agy            Do not install Antigravity (agy) config, rules, or skills.
  --skip-apimanac       Do not fetch, write catalog_root, link the APImanac skill,
                        or register the APImanac MCP server.
  --skip-prompts        Do not install prompts/live-prompts/*.md.
  --skip-telemetry      Do not install the harness-telemetry CLI with uv.
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
  - Symlink prompts/AGENTS.md to each harness's global instructions file
    (~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, ~/.pi/agent/AGENTS.md,
    ~/.config/opencode/AGENTS.md, ~/.config/kilo/AGENTS.md, ~/.grok/AGENTS.md,
    ~/.gemini/GEMINI.md, ~/.gemini/config/rules/AGENTS.md)
    and render it with rule frontmatter to ~/.cursor/rules/agents.mdc.
  - Symlink selected Claude, Codex, Pi, opencode, Kilo Code, Grok, Cursor, and
    Antigravity config paths into their agent homes.
  - Fetch APImanac skill/SKILL.md from GitHub into apis/SKILL.md, write
    catalog_root, and symlink that file into each harness skills/apimanac/.
  - Register the `apimanac mcp` stdio server: user scope for Claude,
    ~/.cursor/mcp.json for Cursor, symlinked config for Codex/opencode/Kilo.
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
    --skip-grok) SKIP_GROK=1 ;;
    --skip-cursor) SKIP_CURSOR=1 ;;
    --skip-agy) SKIP_AGY=1 ;;
    --skip-apimanac) SKIP_APIMANAC=1 ;;
    --skip-prompts) SKIP_PROMPTS=1 ;;
    --skip-telemetry) SKIP_TELEMETRY=1 ;;
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

  # a dangling link carries nothing worth backing up
  if [ -L "$target" ] && [ ! -e "$target" ]; then
    log "Remove: $target (dangling -> $(readlink "$target"))"
    run rm -f "$target"
  elif [ -e "$target" ] || [ -L "$target" ]; then
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
  install_link "$AGENTS_SRC" "$HOME/.claude/CLAUDE.md"
  install_link "$HARNESSES/claude/settings.json" "$HOME/.claude/settings.json"
  install_link "$HARNESSES/claude/settings.local.json" "$HOME/.claude/settings.local.json"
  install_link "$HARNESSES/claude/settings.local-llm.json" "$HOME/.claude/settings.local-llm.json"
  install_link "$HARNESSES/claude/claude-local" "$HOME/.local/bin/claude-local"
  install_link "$HARNESSES/claude/output-styles" "$HOME/.claude/output-styles"
  install_link "$HARNESSES/claude/commands/agent-skills" "$HOME/.claude/commands/agent-skills"
  install_link "$HARNESSES/claude/skills/graphify" "$HOME/.claude/skills/graphify"
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
  install_link "$AGENTS_SRC" "$HOME/.codex/AGENTS.md"
  install_link "$HARNESSES/codex/notify-dispatch.sh" "$HOME/.codex/notify-dispatch.sh"
  install_link "$HARNESSES/codex/config.toml" "$HOME/.codex/config.toml"
  install_link "$HARNESSES/codex/hooks.json" "$HOME/.codex/hooks.json"
  install_link "$HARNESSES/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
  install_link "$HARNESSES/codex/skills/hatch-pet" "$HOME/.codex/skills/hatch-pet"
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
  install_link "$AGENTS_SRC" "$HOME/.pi/agent/AGENTS.md"
  install_link "$HARNESSES/pi-agent/themes/mypi.json" "$HOME/.pi/agent/themes/mypi.json"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_live_prompts "Pi" "$HOME/.pi/agent/prompts"
  fi
}

install_opencode() {
  log "==> opencode"
  install_link "$AGENTS_SRC" "$HOME/.config/opencode/AGENTS.md"
  install_link "$HARNESSES/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"
  install_link "$HARNESSES/opencode/tui.json" "$HOME/.config/opencode/tui.json"
  install_link "$HARNESSES/opencode/themes/mypi.json" "$HOME/.config/opencode/themes/mypi.json"
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
  install_link "$AGENTS_SRC" "$HOME/.config/kilo/AGENTS.md"
  install_link "$HARNESSES/kilo/kilo.jsonc" "$HOME/.config/kilo/kilo.jsonc"
}

install_grok() {
  log "==> Grok"
  install_link "$AGENTS_SRC" "$HOME/.grok/AGENTS.md"
}

refresh_apimanac_skill() {
  local dest="$ROOT/apis/SKILL.md"
  local url="$APIMANAC_SKILL_URL"
  local tmp

  [ -d "$(dirname "$dest")" ] || die "missing APImanac directory: $(dirname "$dest")"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: fetch %s -> %s\n' "$url" "$dest"
    return 0
  fi

  command -v curl >/dev/null 2>&1 ||
    die "curl is required to refresh the APImanac skill from $url"

  tmp="$(mktemp)"
  if ! curl -fsSL -o "$tmp" "$url"; then
    rm -f "$tmp"
    die "failed to fetch APImanac skill from $url"
  fi

  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    die "fetched APImanac skill from $url is empty"
  fi

  if ! grep -q '^name: apimanac$' "$tmp"; then
    rm -f "$tmp"
    die "fetched file from $url is not the APImanac skill"
  fi

  if [ -f "$dest" ] && [ ! -L "$dest" ] && cmp -s "$tmp" "$dest"; then
    log "OK: $dest"
    rm -f "$tmp"
    return 0
  fi

  log "Refresh: $url -> $dest"
  rm -f "$dest"
  mv "$tmp" "$dest"
}

install_apimanac_skill() {
  local dest_dir="$1"
  local skill="$ROOT/apis/SKILL.md"

  [ -f "$skill" ] || die "missing APImanac skill: $skill"
  ensure_real_dir "$dest_dir"
  install_link "$skill" "$dest_dir/SKILL.md"
}

install_apimanac_config() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/apimanac"
  local target="$config_dir/config.yaml"
  local catalog="$ROOT/apis"
  local content="catalog_root: $catalog"

  [ -d "$catalog/catalog" ] || die "missing APImanac catalog: $catalog/catalog"
  command -v apimanac >/dev/null 2>&1 || log "WARN: apimanac is not on PATH"
  # apimanac shells out to git to decide which profiles are committed; without
  # git every profile reads as non-executable.
  command -v git >/dev/null 2>&1 || log "WARN: git is not on PATH; apimanac will treat the catalog as uncommitted"

  if [ -f "$target" ] && [ ! -L "$target" ] && [ "$(cat "$target")" = "$content" ]; then
    log "OK: $target"
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

  ensure_parent_dir "$target"
  log "Write: $target"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: write %s <- %s\n' "$target" "$content"
  else
    printf '%s\n' "$content" > "$target"
  fi
}

claude_apimanac_mcp_state() {
  python3 - "${CLAUDE_CONFIG_DIR:-$HOME}/.claude.json" <<'PY'
import json
import sys

try:
    with open(sys.argv[1]) as handle:
        servers = json.load(handle).get("mcpServers") or {}
except (OSError, ValueError):
    print("missing")
    raise SystemExit(0)

entry = servers.get("apimanac") or {}
if not entry:
    print("missing")
elif entry.get("command") == "apimanac" and entry.get("args") == ["mcp"]:
    print("match")
else:
    print("differs")
PY
}

install_claude_apimanac_mcp() {
  local state

  # Claude keeps user-scope MCP servers in ~/.claude.json, which the CLI
  # rewrites at runtime, so register through `claude mcp` instead of a symlink.
  if ! command -v claude >/dev/null 2>&1; then
    log "WARN: claude is not on PATH; skipping Claude MCP registration"
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    log "WARN: python3 is not on PATH; skipping Claude MCP registration"
    return 0
  fi

  state="$(claude_apimanac_mcp_state)"
  case "$state" in
    match)
      log "OK: Claude MCP apimanac (user scope)"
      return 0
      ;;
    differs)
      log "Replace: Claude MCP apimanac (user scope)"
      run claude mcp remove apimanac -s user
      ;;
  esac

  log "Register: Claude MCP apimanac (user scope)"
  run claude mcp add --scope user apimanac -- apimanac mcp
}

merge_cursor_apimanac_mcp() {
  python3 - "$1" <<'PY'
import json
import os
import sys

path = sys.argv[1]
config = {}
if os.path.exists(path):
    try:
        with open(path) as handle:
            config = json.load(handle)
    except ValueError:
        raise SystemExit(1)
    if not isinstance(config, dict):
        raise SystemExit(1)

servers = config.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    raise SystemExit(1)

desired = {"command": "apimanac", "args": ["mcp"]}
if servers.get("apimanac") == desired:
    print(f"OK: {path} (apimanac)")
    raise SystemExit(0)

servers["apimanac"] = desired
with open(path, "w") as handle:
    json.dump(config, handle, indent=2)
    handle.write("\n")
print(f"Write: {path} (apimanac)")
PY
}

install_cursor_apimanac_mcp() {
  local target="$HOME/.cursor/mcp.json"
  local backup

  # Cursor has no `mcp add` command, and this file holds servers this script
  # does not own, so merge one key instead of writing the whole file.
  if ! command -v python3 >/dev/null 2>&1; then
    log "WARN: python3 is not on PATH; skipping Cursor MCP registration"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: merge apimanac into %s\n' "$target"
    return 0
  fi

  ensure_parent_dir "$target"
  if ! merge_cursor_apimanac_mcp "$target"; then
    backup="$(backup_name_for "$target")"
    log "Backup: $target -> $backup (unparsable JSON)"
    mv "$target" "$backup"
    merge_cursor_apimanac_mcp "$target" ||
      die "failed to write $target"
  fi
}

merge_agy_apimanac_mcp() {
  python3 - "$1" <<'PY'
import json
import os
import sys

path = sys.argv[1]
config = {}
if os.path.exists(path):
    try:
        with open(path) as handle:
            content = handle.read().strip()
            if content:
                config = json.loads(content)
    except ValueError:
        raise SystemExit(1)
    if not isinstance(config, dict):
        raise SystemExit(1)

servers = config.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    raise SystemExit(1)

desired = {"command": "apimanac", "args": ["mcp"]}
existing = servers.get("apimanac")
if (
    isinstance(existing, dict)
    and existing.get("command") == "apimanac"
    and existing.get("args") == ["mcp"]
    and not existing.get("disabled", False)
):
    print(f"OK: {path} (apimanac)")
    raise SystemExit(0)

servers["apimanac"] = desired
with open(path, "w") as handle:
    json.dump(config, handle, indent=2)
    handle.write("\n")
print(f"Write: {path} (apimanac)")
PY
}

install_agy_apimanac_mcp() {
  local target="$HOME/.gemini/config/mcp_config.json"
  local backup

  if ! command -v python3 >/dev/null 2>&1; then
    log "WARN: python3 is not on PATH; skipping Antigravity MCP registration"
    return 0
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: merge apimanac into %s\n' "$target"
    return 0
  fi

  ensure_parent_dir "$target"
  if ! merge_agy_apimanac_mcp "$target"; then
    backup="$(backup_name_for "$target")"
    log "Backup: $target -> $backup (unparsable JSON)"
    mv "$target" "$backup"
    merge_agy_apimanac_mcp "$target" ||
      die "failed to write $target"
  fi
}

install_apimanac() {
  log "==> APImanac"
  refresh_apimanac_skill
  install_apimanac_config

  # Link the skill into each selected harness. Do not put it in
  # ~/.agents/skills — that tree is the skillquarium submodule checkout.
  if [ "$SKIP_CLAUDE" -eq 0 ]; then
    install_apimanac_skill "$HOME/.claude/skills/apimanac"
  fi
  if [ "$SKIP_CODEX" -eq 0 ]; then
    install_apimanac_skill "$HOME/.codex/skills/apimanac"
  fi
  if [ "$SKIP_PI" -eq 0 ]; then
    install_apimanac_skill "$HOME/.pi/agent/skills/apimanac"
  fi
  if [ "$SKIP_OPENCODE" -eq 0 ]; then
    install_apimanac_skill "$HOME/.config/opencode/skills/apimanac"
  fi
  if [ "$SKIP_KILO" -eq 0 ]; then
    install_apimanac_skill "$HOME/.kilo/skills/apimanac"
  fi
  if [ "$SKIP_CURSOR" -eq 0 ]; then
    install_apimanac_skill "$HOME/.cursor/skills/apimanac"
  fi
  if [ "$SKIP_AGY" -eq 0 ]; then
    install_apimanac_skill "$HOME/.gemini/config/skills/apimanac"
  fi

  # Register the stdio MCP server (`apimanac mcp`). Codex, opencode, and Kilo
  # declare it in their symlinked config files; Pi has no native MCP support.
  if [ "$SKIP_CLAUDE" -eq 0 ]; then
    install_claude_apimanac_mcp
  fi
  if [ "$SKIP_CURSOR" -eq 0 ]; then
    install_cursor_apimanac_mcp
  fi
  if [ "$SKIP_AGY" -eq 0 ]; then
    install_agy_apimanac_mcp
  fi
}

install_cursor_rules() {
  local target_dir="$HOME/.cursor/rules"
  local rendered stale

  # Cursor has no home-level AGENTS.md; rules need .mdc frontmatter, so render
  # the shared source into a copy instead of symlinking it.
  rendered="$(mktemp)"
  {
    printf -- '---\ndescription: Personal operating rules shared across agent harnesses\nalwaysApply: true\n---\n\n'
    cat "$AGENTS_SRC"
  } > "$rendered"
  chmod 644 "$rendered"
  install_copy "$rendered" "$target_dir/agents.mdc"
  rm -f "$rendered"

  # Drop links left by the old per-section rule files.
  for stale in behaviors context-hygiene dev skills; do
    stale="$target_dir/$stale.mdc"
    if [ -L "$stale" ] && [[ "$(readlink "$stale")" == "$HARNESSES/cursor/rules/"* ]]; then
      log "Remove: $stale (superseded by agents.mdc)"
      run rm -f "$stale"
    fi
  done
}

install_cursor() {
  log "==> Cursor"
  install_cursor_rules

  # Copy, do not symlink: the CLI rewrites this file with auth and caches.
  install_copy "$HARNESSES/cursor/cli-config.json" "$HOME/.cursor/cli-config.json"
}

merge_agy_settings() {
  python3 - "$1" "$2" <<'PY'
import json
import os
import sys

source_path, target_path = sys.argv[1], sys.argv[2]
with open(source_path) as handle:
    source = json.load(handle)

target = {}
if os.path.exists(target_path):
    try:
        with open(target_path) as handle:
            content = handle.read().strip()
            if content:
                target = json.loads(content)
    except ValueError:
        raise SystemExit(1)
    if not isinstance(target, dict):
        raise SystemExit(1)

changed = False
for key, value in source.items():
    if target.get(key) != value:
        target[key] = value
        changed = True

if not changed and os.path.exists(target_path):
    print(f"OK: {target_path} matches {source_path}")
    raise SystemExit(0)

with open(target_path, "w") as handle:
    json.dump(target, handle, indent=2)
    handle.write("\n")
print(f"Merge: {source_path} -> {target_path}")
PY
}

install_agy_settings() {
  local source="$1"
  local target="$2"
  local backup

  if ! command -v python3 >/dev/null 2>&1; then
    install_copy "$source" "$target"
    return 0
  fi

  ensure_parent_dir "$target"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: merge %s into %s\n' "$source" "$target"
    return 0
  fi

  if ! merge_agy_settings "$source" "$target"; then
    backup="$(backup_name_for "$target")"
    log "Backup: $target -> $backup (unparsable JSON)"
    mv "$target" "$backup"
    merge_agy_settings "$source" "$target" ||
      die "failed to write $target"
  fi
}

install_agy() {
  log "==> Antigravity (agy)"
  install_link "$AGENTS_SRC" "$HOME/.gemini/GEMINI.md"
  install_link "$AGENTS_SRC" "$HOME/.gemini/config/rules/AGENTS.md"
  install_agy_settings "$HARNESSES/agy/settings.json" "$HOME/.gemini/antigravity-cli/settings.json"
  install_link "$HARNESSES/agy/keybindings.json" "$HOME/.gemini/antigravity-cli/keybindings.json"
  install_link "$HARNESSES/agy/skills.json" "$HOME/.gemini/config/skills.json"
  install_link "$ROOT/agents/code-reviewer.md" "$HOME/.gemini/config/agents/code-reviewer.md"
  install_link "$ROOT/agents/security-auditor.md" "$HOME/.gemini/config/agents/security-auditor.md"
  install_link "$ROOT/agents/test-engineer.md" "$HOME/.gemini/config/agents/test-engineer.md"
  install_link "$ROOT/agents/web-performance-auditor.md" "$HOME/.gemini/config/agents/web-performance-auditor.md"
  if [ "$SKIP_PROMPTS" -eq 0 ]; then
    install_live_prompts "Antigravity" "$HOME/.gemini/config/workflows"
  fi
}

install_telemetry() {
  log "==> harness-telemetry"
  if ! command -v uv >/dev/null 2>&1; then
    log "Skip: harness-telemetry (uv not on PATH)"
    return 0
  fi
  # editable install so edits under harness-telemetry/ apply without reinstalling
  run uv tool install --quiet --editable --reinstall "$ROOT/harness-telemetry"
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

  if [ "$SKIP_GROK" -eq 0 ]; then
    install_grok
  else
    log "Skip: Grok"
  fi

  if [ "$SKIP_CURSOR" -eq 0 ]; then
    install_cursor
  else
    log "Skip: Cursor"
  fi

  if [ "$SKIP_AGY" -eq 0 ]; then
    install_agy
  else
    log "Skip: Antigravity (agy)"
  fi

  if [ "$SKIP_APIMANAC" -eq 0 ]; then
    install_apimanac
  else
    log "Skip: APImanac"
  fi

  if [ "$SKIP_TELEMETRY" -eq 0 ]; then
    install_telemetry
  else
    log "Skip: harness-telemetry"
  fi
}

main
