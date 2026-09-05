# AGENTS.md - dot-agents operating guide

This repository stores personal agent configuration. Treat it like dotfiles for
agent harnesses: useful to version, but easy to accidentally pollute with local
state.

## Before Editing

1. Read `README.md` and `docs/sources.md`.
2. Inspect the relevant agent folder before changing it.
3. If the change depends on an external agent/config project, use `opensrc` or
   the real source repository before copying patterns.
4. Check `git status --short` before and after edits.

## Rules

- Do not commit auth material, local histories, sessions, logs, caches, generated
  images, SQLite state, browser state, or app telemetry.
- Keep the `skills/` directory as a submodule for `stanfish06/skillquarium`.
- Put agent-specific configuration under that agent's folder, not at the root,
  unless the file is meant to guide this repository itself.
- Put future lifecycle hook experiments under `hooks/`.
- Put refresh/install/validation helpers under `scripts/`.
- Put spec-driven development notes, templates, and SDD harness experiments
  under `spec/` (see `spec/README.md`). Do not force third-party SDD products
  into every agent home by default.
- Update `README.md` when the layout changes.
- After changing the submodule, verify with `git submodule status`.

## Current Sources

- Global instructions: `prompts/AGENTS.md` is the only copy. `scripts/install.sh`
  symlinks it to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.pi/agent/AGENTS.md`, `~/.config/opencode/AGENTS.md`,
  `~/.config/kilo/AGENTS.md`, `~/.grok/AGENTS.md`, `~/.gemini/GEMINI.md`, and
  `~/.gemini/config/rules/AGENTS.md`, and renders it to
  `~/.cursor/rules/agents.mdc`. Do not add a per-harness instructions file.
- Claude source: `~/.claude/settings*.json` and `~/.claude/skills/graphify`.
- Codex source: `~/.codex/config.toml`, `~/.codex/rules/default.rules`, and
  `~/.codex/skills/hatch-pet`.
- Pi source: `~/.pi/agent/themes/mypi.json`.
- opencode source: `~/.config/opencode/opencode.jsonc`. opencode auto-loads
  skills from `~/.agents/skills/` and `~/.claude/skills/`, so no separate skill
  wiring is needed.
- Kilo Code source: `~/.config/kilo/kilo.jsonc`, wired for the OpenRouter
  provider (BYOK). The API key is read from the `OPENROUTER_API_KEY` env var.
- Cursor source: `harnesses/cursor/cli-config.json` (copied to
  `~/.cursor/cli-config.json`). `approvalMode` is `unrestricted` (Run
  Everything). Do not commit the live CLI file; it accumulates auth and caches.
  Cursor has no `~/.cursor/AGENTS.md`; CLI/IDE also read project-root
  `AGENTS.md` / `CLAUDE.md` and `<project>/.cursor/rules`.
- Antigravity (agy) source: `harnesses/agy/settings.json`, `harnesses/agy/keybindings.json`, and
  `harnesses/agy/skills.json`. Global instructions are linked to `~/.gemini/GEMINI.md` and
  `~/.gemini/config/rules/AGENTS.md`, specialist personas to
  `~/.gemini/config/agents/`, live prompts to `~/.gemini/config/workflows/`, and
  `skills.json` discovers `~/.agents/skills/`.
- Skills source: `git@github.com:stanfish06/skillquarium.git`.
- APImanac source: `apis/` (catalog locally; `SKILL.md` refreshed from
  `stanfish06/APImanac` `skill/SKILL.md` on each install). Installed as
  `$XDG_CONFIG_HOME/apimanac/config.yaml` `catalog_root` and as
  `skills/apimanac/SKILL.md` in each harness home. Not part of the
  `skills/` submodule. The `apimanac mcp` stdio server is declared in the
  symlinked Codex/opencode/Kilo configs, added at user scope for Claude
  (`~/.claude.json`, written by `claude mcp add`), and merged into
  `~/.cursor/mcp.json` and `~/.gemini/config/mcp_config.json`. Pi has no native MCP support.

## Office Files

- For any task involving Word (`.docx`), Excel (`.xlsx`/`.csv`), or PowerPoint
  (`.pptx`) files, check and invoke the OfficeCLI skills before acting. Use
  `officecli-docx`, `officecli-xlsx`, or `officecli-pptx` for format-specific
  work and `officecli` for general or cross-format work.
- Load the matching specialized skill when applicable:
  `officecli-academic-paper`, `officecli-data-dashboard`,
  `officecli-financial-model`, `officecli-pitch-deck`,
  `officecli-word-form`, `morph-ppt`, or `morph-ppt-3d`. Scene-layer skills
  inherit their base OfficeCLI skill, so read both when the specialized skill
  says to do so.
- Follow the selected skill's help-first and delivery/visual-validation rules.
  Use `officecli help` when command syntax or properties are uncertain instead
  of guessing.
