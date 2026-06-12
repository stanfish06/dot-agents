# Source Notes

Reference repos were inspected with `opensrc` on 2026-06-12.

## Reference Layouts

`addyosmani/agent-skills` keeps portable skills in `skills/`, Claude slash
commands in `.claude/commands/`, plugin metadata in `.claude-plugin/`, reusable
personas in `agents/`, future automation in `hooks/`, validation in `scripts/`,
and setup docs in `docs/`.

`obra/superpowers` uses a similar split but is more explicitly multi-harness:
root `AGENTS.md`/`CLAUDE.md` instructions, `.claude-plugin/`, `.codex-plugin/`,
`.cursor-plugin/`, `.opencode/`, `skills/`, `hooks/`, `scripts/`, `docs/`, and
`tests/`. Its Codex plugin manifest points Codex at `./skills/` while UI metadata
lives beside it.

The useful shared pattern is separation by responsibility:

- portable skill content
- agent-specific metadata and instructions
- lifecycle hooks
- install/sync scripts
- tests and docs

## Local Import

Imported from Claude:

- `~/.claude/CLAUDE.md`
- `~/.claude/settings.json`
- `~/.claude/settings.local.json`
- `~/.claude/skills/graphify`

Imported from Codex:

- `~/.codex/AGENTS.md`
- `~/.codex/config.toml`
- `~/.codex/rules/default.rules`
- `~/.codex/skills/hatch-pet`

Added as a submodule:

- `skills/` -> `https://github.com/stanfish06/my-skills.git`

Imported from `addyosmani/agent-skills`:

- 23 production engineering skills into the `skills/` submodule. The duplicate
  `test-driven-development` skill was skipped in favor of the vault's existing
  Superpowers version.
- Claude slash commands under `claude/commands/agent-skills/`.
- Specialist personas under `agents/`.
- Claude hook scripts and docs under `hooks/`.

Imported from `obra/superpowers`:

- Session-start hook bootstrap and cross-platform hook runner under `hooks/`.
- Hook JSON examples for Claude and Cursor under `hooks/`.

Intentionally excluded:

- `~/.claude.json`, because it is app state with account/cache/project metadata.
- `~/.codex/auth.json`, OAuth/auth files, and credential-like state.
- histories, sessions, logs, shell snapshots, browser/computer-use state,
  generated images, plugin caches, SQLite databases, and temp folders.
