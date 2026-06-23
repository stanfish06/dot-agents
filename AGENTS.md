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
- Keep the `skills/` directory as a submodule for `stanfish06/my-skills`.
- Put agent-specific configuration under that agent's folder, not at the root,
  unless the file is meant to guide this repository itself.
- Put future lifecycle hook experiments under `hooks/`.
- Put refresh/install/validation helpers under `scripts/`.
- Update `README.md` when the layout changes.
- After changing the submodule, verify with `git submodule status`.

## Current Sources

- Claude source: `~/.claude/CLAUDE.md`, `~/.claude/settings*.json`, and
  `~/.claude/skills/graphify`.
- Codex source: `~/.codex/AGENTS.md`, `~/.codex/config.toml`,
  `~/.codex/rules/default.rules`, and `~/.codex/skills/hatch-pet`.
- opencode source: `~/.config/opencode/AGENTS.md` and
  `~/.config/opencode/opencode.jsonc`. opencode auto-loads skills from
  `~/.agents/skills/` and `~/.claude/skills/`, so no separate skill wiring
  is needed.
- Skills source: `https://github.com/stanfish06/my-skills.git`.
