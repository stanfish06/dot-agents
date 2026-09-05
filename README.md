# dot-agents

Personal configuration for coding agents.

This repo keeps the durable, reviewable parts of the agent setup in one place:
global instructions, declarative settings, portable rules, personal skills, and
future hook glue. Runtime state, auth material, histories, caches, and generated
artifacts stay out of git.

## Layout

- `skills/` - submodule for `stanfish06/skillquarium`, the reusable skill vault.
- `.github/` - Dependabot and validation automation for advancing the `skills`
  submodule pin.
- `agents/` - reusable specialist personas imported from production agent packs.
- `prompts/AGENTS.md` - the one global instructions file. The installer
  symlinks it to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.pi/agent/AGENTS.md`, `~/.config/opencode/AGENTS.md`,
  `~/.config/kilo/AGENTS.md`, `~/.grok/AGENTS.md`, `~/.gemini/GEMINI.md`, and
  `~/.gemini/config/rules/AGENTS.md`, and renders it with rule frontmatter to
  `~/.cursor/rules/agents.mdc`. Edit this file only; the per-harness folders no
  longer carry their own copy.
- `harnesses/` - one folder per agent harness (Claude, Codex, Pi, opencode, Kilo,
  Cursor, Antigravity). Each holds the selected files the installer symlinks or
  copies into that harness's home:
- `harnesses/claude/` - selected files from `~/.claude`: settings and
  the standalone `graphify` skill, plus optional slash commands under
  `harnesses/claude/commands/`. `harnesses/claude/settings.local-llm.json` and the `claude-local`
  launcher (linked to `~/.local/bin/claude-local`) point Claude Code at the
  llama.cpp server on `stanfishdeb` over Tailscale; see "Local model" below.
- `harnesses/codex/` - selected files from `~/.codex`: config, default rules, hooks, and
  the `hatch-pet` skill.
- `harnesses/pi-agent/` - selected Pi agent config: the `mypi` theme.
- `harnesses/opencode/` - selected opencode config: `opencode.jsonc`, `tui.json` +
  `themes/mypi.json` (the Pi theme ported to opencode's theme format). opencode
  auto-loads skills from `~/.agents/skills/` and `~/.claude/skills/`, so no
  separate skill wiring is needed.
- `harnesses/kilo/` - Kilo Code config: `kilo.jsonc` wired for OpenRouter (BYOK). The API
  key is read from the `OPENROUTER_API_KEY` env var, never committed.
- `harnesses/cursor/` - a sanitized `cli-config.json` (`approvalMode: unrestricted`, i.e.
  Run Everything), copied to `~/.cursor/cli-config.json` so the CLI can rewrite
  caches without dirtying git. Cursor has no home-directory `AGENTS.md`, so the
  installer renders `prompts/AGENTS.md` to `~/.cursor/rules/agents.mdc` as a
  copy with `alwaysApply: true` frontmatter. Project `AGENTS.md` /
  `.cursor/rules` stay in each repo.
- `harnesses/agy/` - Antigravity (`agy`) CLI and runtime configuration: `settings.json`
  (durable model preferences), `keybindings.json` (custom keyboard shortcuts),
  and `skills.json` (discovering `~/.agents/skills`). Global instructions are
  linked to `~/.gemini/GEMINI.md` and `~/.gemini/config/rules/AGENTS.md`,
  specialist personas to `~/.gemini/config/agents/`, and live prompts to
  `~/.gemini/config/workflows/`.
- `apis/` - personal APImanac catalog (`catalog/meta`, `catalog/execution`)
  for [APImanac](https://github.com/stanfish06/APImanac) plus `SKILL.md` fetched
  from [stanfish06/APImanac](https://github.com/stanfish06/APImanac)
  `skill/SKILL.md`. The installer writes `catalog_root` to
  `$XDG_CONFIG_HOME/apimanac/config.yaml` and symlinks the skill into each
  harness `skills/apimanac/` directory. Grants stay in the untracked XDG
  grants file, not here. The `apimanac mcp` stdio server is registered per
  harness: `[mcp_servers.apimanac]` in `harnesses/codex/config.toml`, an `mcp` block in
  `harnesses/opencode/opencode.jsonc` and `harnesses/kilo/kilo.jsonc`, user scope via
  `claude mcp add` for Claude, and a merged entry in `~/.cursor/mcp.json` and
  `~/.gemini/config/mcp_config.json`. Pi has no native MCP support.
- `prompts/` - the shared `AGENTS.md`, reusable system prompts, and live prompt
  templates for agent slash-command surfaces.
- `hooks/` - opt-in Claude hook scripts and hook JSON examples.
- `harness-telemetry/` - `uv` package with the `harness-telemetry` CLI. It parses
  the session logs that Claude Code, Codex, opencode, Kilo, and Pi already write
  to disk into one DuckDB file and reports tool calls, skill usage, prompts, and
  tokens per harness, session, or project. See "Telemetry" below.
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

## Automatic Skills Updates

The `skills/` submodule tracks the `master` branch of
`stanfish06/skillquarium`. Dependabot checks it daily and opens an update pull
request when the recorded commit is behind. A narrowly scoped workflow verifies
that the pull request changes only the `skills` gitlink, checks the submodule and
installer contract, and merges it when those checks pass.

After pulling this repository, update the local checkout to its newly recorded
pin:

```bash
git pull --recurse-submodules
```

To fetch the current upstream head before Dependabot advances the remote pin:

```bash
git submodule update --init --remote --checkout skills
```

## Install

```bash
./scripts/install.sh
```

The installer is symlink-first for agent config. It initializes the `skills/`
submodule, delegates skill installation to `skills/install-skills.sh`, links
`prompts/AGENTS.md` to each harness's global instructions path (Cursor gets a
rendered `.mdc` copy), then links the selected Claude, Codex, Pi, opencode,
Kilo Code, Grok, Cursor, and Antigravity config into their agent homes. It fetches `skill/SKILL.md` from
[stanfish06/APImanac](https://github.com/stanfish06/APImanac) into
`apis/SKILL.md`, writes the APImanac `catalog_root`, symlinks that
file into each harness `skills/apimanac/` directory, and registers the
`apimanac mcp` server for Claude (user scope), Cursor, and Antigravity. It also links
`prompts/live-prompts/*.md` into each agent's live prompt, command, or workflow directory.
Existing non-matching files are moved aside to timestamped backups.

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

## Telemetry

`harness-telemetry` reads the session stores each harness keeps locally and
normalizes them into `$XDG_DATA_HOME/dot-agents/telemetry.duckdb` (override with
`DOT_AGENTS_TELEMETRY_DB`). No hooks or exporters run inside the harnesses; the
parsers only read files that are already there. Sources:

| Harness | Store | Skill signal |
|---|---|---|
| Claude Code | `~/.claude/projects/**/*.jsonl` | `Skill` tool call (`invoke`) |
| Codex | `~/.codex/sessions/**/rollout-*.jsonl` | `SKILL.md` path in a tool call (`read`) |
| opencode | `~/.local/share/opencode/opencode.db` | `skill` tool call (`invoke`) |
| Kilo | `~/.local/share/kilo/kilo.db` | `skill` tool call (`invoke`) |
| Pi | `~/.pi/agent/sessions/**/*.jsonl` | `SKILL.md` path in a tool call (`read`) |

`install.sh` installs the CLI with `uv tool install --editable`. Then:

```bash
harness-telemetry ingest                 # incremental; re-parses only changed files
harness-telemetry report summary         # one row per harness
harness-telemetry report skills -d 30    # skills used in the last 30 days
harness-telemetry report tools -H claude -H codex
harness-telemetry report sessions -p dot-agents
harness-telemetry sql "select name, count(*) from events where kind='tool' group by 1"
```

Codex and Pi have no native skill tool, so a skill counts there whenever a tool
call mentions `<name>/SKILL.md`. That measures reads, not invocations. Cursor
is not parsed yet.

## Local model

`claude-local` runs Claude Code against the llama.cpp server on `stanfishdeb`
(`https://stanfishdeb.tail861ef1.ts.net`, Anthropic-compatible `/v1/messages`,
currently `qwen3-27b` with a 32768-token context). It passes
`--settings harnesses/claude/settings.local-llm.json --strict-mcp-config --bare`, so no
hooks, plugins, MCP servers, CLAUDE.md, or auto-memory load. Bare mode exposes
only Bash, Edit, and Read (about 900 tokens) behind a two-line system prompt,
so the launcher appends a short instruction telling the model to act through
those tools instead of printing commands; the whole prompt stays near 1.2k
tokens. `CLAUDE_LOCAL_FULL=1` drops `--bare` and loads the normal profile: 24
tools (about 12k tokens), the full system prompt, and CLAUDE.md, about 23k of
the 32k window before the first message.

```bash
claude-local
claude-local -p "explain this repo"
CLAUDE_LOCAL_FULL=1 claude-local
```

Model name, URL, and context size live in `harnesses/claude/settings.local-llm.json`
(`ANTHROPIC_MODEL`, `ANTHROPIC_BASE_URL`, `CLAUDE_CODE_MAX_CONTEXT_TOKENS` under
`env`). The server ignores the Anthropic `thinking` parameter, so Qwen3 reasons
on every turn unless `llama-server` runs with `--reasoning-budget 0`. Claude Code
sends no sampling parameters, so the server defaults apply (temperature 0.8,
top-k 40); Qwen's published settings for tool use are `--temp 0.7 --top-p 0.8
--top-k 20 --min-p 0`, and a 4B model at 0.8 will sometimes print a command as
text instead of calling the tool.

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

