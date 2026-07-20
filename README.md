# dot-agents

Personal configuration for coding agents.

This repo keeps the durable, reviewable parts of the agent setup in one place:
global instructions, declarative settings, portable rules, personal skills, and
future hook glue. Runtime state, auth material, histories, caches, and generated
artifacts stay out of git.

## Layout

- `skills/` - submodule for `stanfish06/skillquarium`, the reusable skill vault.
- `agents/` - reusable specialist personas imported from production agent packs.
- `claude/` - selected files from `~/.claude`: global instructions, settings, and
  the standalone `graphify` skill, plus optional slash commands under
  `claude/commands/`.
- `codex/` - selected files from `~/.codex`: global instructions, config, default
  rules, hooks, and the `hatch-pet` skill.
- `pi-agent/` - selected Pi agent config, currently the `mypi` theme.
- `opencode/` - selected opencode config: global `AGENTS.md` operating guide,
  `opencode.jsonc`, `tui.json` + `themes/mypi.json` (the Pi theme ported to
  opencode's theme format). opencode auto-loads skills from `~/.agents/skills/`
  and `~/.claude/skills/`, so no separate skill wiring is needed.
- `kilo/` - Kilo Code config: `kilo.jsonc` wired for OpenRouter (BYOK). The
  API key is read from the `OPENROUTER_API_KEY` env var, never committed.
- `prompts/` - reusable system prompts and live prompt templates for agent
  slash-command surfaces.
- `hooks/` - opt-in Claude hook scripts and hook JSON examples.
- `scripts/` - reserved for install, refresh, and validation helpers.
- `spec/` - notes and future harness experiments for spec-driven development
  (catalog of mainstream SDD tools, local templates later). See `spec/README.md`.
- `docs/sources.md` - notes from the reference repos and the local import.

## First Checkout

```bash
git submodule update --init --recursive
```

The `skills/` submodule is intentionally separate from the agent-specific config
folders. Agent harnesses can symlink or install skills from that vault while this
repo also tracks harness configuration around them.

## Install

```bash
./scripts/install.sh
```

The installer is symlink-first for agent config. It initializes the `skills/`
submodule, delegates skill installation to `skills/install-skills.sh`, then links
the selected Claude, Codex, Pi, opencode, and Kilo Code config into their agent
homes. It also links `prompts/live-prompts/*.md` into each agent's live prompt or
command directory. Existing non-matching files are moved aside to timestamped
backups.

The skills installer skips the optional `gstack` and `career-ops` extras by
default. Select either or both through the parent installer:

```bash
./scripts/install.sh --extras gstack
./scripts/install.sh --extras career
./scripts/install.sh --extras gstack career
./scripts/install.sh --extras all
```

Preview changes without touching your home directory:

```bash
./scripts/install.sh --dry-run
```

## Imported Reference Content

The submodule includes the selected production engineering skills from
`addyosmani/agent-skills`, excluding the duplicate `test-driven-development`
skill because the vault already carries the Superpowers version. The parent repo
also keeps Addy's specialist personas, Claude slash commands, and opt-in hooks.

The `hooks/` directory also carries the Superpowers session-start bootstrap hook
as an opt-in reference. Do not enable both session-start bootstraps at once unless
you explicitly want both meta-skill introductions injected into every session.

The Claude and Codex stop-summary hooks from `stanfish06/my-configs` are included
as repo-managed scripts. They send a simple desktop notification by default; set
`DOT_AGENTS_STOP_SUMMARY_WITH_CLAUDE=1` to let them ask Claude for a short stop
summary before notifying.

`prompts/system-prompts/deer-flow/` holds portable prompt templates extracted from
[bytedance/deer-flow](https://github.com/bytedance/deer-flow) 2.0 (MIT) — the
lead-agent system prompt, a subagent orchestration prompt, and structured
memory-management prompts. The deer-flow `skills/public` set is being imported
separately into the `stanfish06/skillquarium` vault rather than here, per the
skills-go-in-the-submodule rule.

## Refresh From Home

The current import was intentionally narrow. To refresh it, copy only the same
source-of-truth files and review the diff before committing:

```bash
rsync -a ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/settings.local.json claude/
rsync -a ~/.claude/skills/graphify claude/skills/
rsync -a ~/.codex/config.toml ~/.codex/AGENTS.md codex/
rsync -a ~/.codex/hooks.json codex/
rsync -a ~/.codex/rules/default.rules codex/rules/
rsync -a ~/.codex/skills/hatch-pet codex/skills/
rsync -a ~/.pi/agent/themes/mypi.json pi-agent/themes/
rsync -a ~/.config/opencode/AGENTS.md opencode/
rsync -a ~/.config/opencode/opencode.jsonc opencode/
rsync -a ~/.config/opencode/tui.json opencode/
rsync -a ~/.config/opencode/themes/mypi.json opencode/themes/
rsync -a ~/.config/kilo/kilo.jsonc kilo/
```

Do not import `auth.json`, `.claude.json`, histories, sessions, plugin caches,
SQLite state, generated images, browser state, Pi auth/session state, Kilo
credentials, or temporary folders.
