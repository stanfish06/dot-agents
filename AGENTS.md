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
- Put spec-driven development notes, templates, and SDD harness experiments
  under `spec/` (see `spec/README.md`). Do not force third-party SDD products
  into every agent home by default.
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
- Kilo Code source: `~/.config/kilo/kilo.jsonc`, wired for the OpenRouter
  provider (BYOK). The API key is read from the `OPENROUTER_API_KEY` env var.
- Skills source: `https://github.com/stanfish06/my-skills.git`.

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
