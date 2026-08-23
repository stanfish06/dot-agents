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

- `skills/` -> `git@github.com:stanfish06/skillquarium.git`

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

Imported from `stanfish06/my-configs`:

- Claude notification and stop-summary hook behavior from
  `claude/settings.json` and `claude/stop-summary.sh`.
- Codex stop-summary hook behavior from `codex/hooks.json` and
  `codex/stop-summary-claude.sh`.
- Pi agent theme from `pi-agent/themes/mypi.json`, installed as
  `~/.pi/agent/themes/mypi.json`.

Added for Pi:

- `pi-agent/AGENTS.md` — global instructions installed as
  `~/.pi/agent/AGENTS.md`. Pi loads this at startup along with parent and
  project `AGENTS.md` / `CLAUDE.md` files.

Imported from Kilo Code docs (https://kilocode.ai/docs):

- `kilo/kilo.jsonc` — global Kilo Code config wired for the OpenRouter
  provider (BYOK). The provider is enabled via `enabled_providers`, the API
  key is read from the `OPENROUTER_API_KEY` env var (never committed), and
  per-model `options` are forwarded to OpenRouter as
  `providerOptions.openrouter` (transforms + provider routing). Installed as
  `~/.config/kilo/kilo.jsonc`.
- `kilo/AGENTS.md` — global instructions installed as
  `~/.config/kilo/AGENTS.md`.

Added for Cursor:

- `cursor/rules/*.mdc` — Codex `AGENTS.md` split into always-on user rules
  (`behaviors`, `dev`, `skills`, `context-hygiene`). Installed as
  `~/.cursor/rules/*.mdc`. Cursor docs do not load `~/.cursor/AGENTS.md`;
  Help lists `~/.cursor/rules` as the machine-local user-rule path. Account
  User Rules in Customize → Rules are not files and are not installed.
  Project `AGENTS.md` / `.cursor/rules` stay in each repo.
- `cursor/cli-config.json` — durable CLI settings imported from
  `~/.cursor/cli-config.json`, with auth, privacy, and server caches
  stripped. `approvalMode` is `unrestricted` (Run Everything / `--yolo`).
  Installed as a copy to `~/.cursor/cli-config.json` so the CLI can rewrite
  runtime fields without dirtying git.

Intentionally excluded:

- `~/.claude.json`, because it is app state with account/cache/project metadata.
- `~/.codex/auth.json`, OAuth/auth files, and credential-like state.
- `~/.pi/agent/auth.json`, Pi sessions, and Pi-installed skills.
- `~/.config/kilo/` credentials, Kilo account/session state, and any
  `provider.*.options.apiKey` values. The OpenRouter key lives in the
  `OPENROUTER_API_KEY` env var.
- Live `~/.cursor/cli-config.json` auth/cache fields (`authInfo`,
  `privacyCache`, `autoReviewAvailabilityCache`, `serverConfigCache`,
  `modelSelectionHistory`), plus chats, project caches, `skills-cursor`,
  and other Cursor runtime state.
- histories, sessions, logs, shell snapshots, browser/computer-use state,
  generated images, plugin caches, SQLite databases, and temp folders.
