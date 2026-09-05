# Prompts

## Global instructions

`AGENTS.md` here is the single source for every harness's global instructions.
`scripts/install.sh` symlinks it to `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
`~/.pi/agent/AGENTS.md`, `~/.config/opencode/AGENTS.md`,
`~/.config/kilo/AGENTS.md`, and `~/.grok/AGENTS.md`. Cursor only reads `.mdc`
rules with frontmatter, so the installer writes a rendered copy to
`~/.cursor/rules/agents.mdc`; rerun the installer after editing to refresh it.

## System prompts

Load one at session start.

```bash
claude --system-prompt "$(< file)"
codex  --config developer_instructions="$(< file)"
pi     --system-prompt "$(< file)"   # or --append-system-prompt to add without replacing
```

**opencode** has no per-invocation system-prompt flag. Add the file to the
`instructions` array in `opencode.jsonc` (it is appended to the system prompt at
session start):

```jsonc
{ "instructions": ["AGENTS.md", "prompts/system-prompts/deer-flow/lead-agent-system-prompt.md"] }
```

Alternatively define an agent at `~/.config/opencode/agent/<name>.md` whose body
is the system prompt, then run `opencode --agent <name>`.

**Pi** also supports file conventions instead of the flag: drop the prompt at
`~/.pi/agent/SYSTEM.md` (global) or `.pi/SYSTEM.md` (project) to replace the
default, or `APPEND_SYSTEM.md` in either location to append to it.

`system-prompts/` also holds curated extracts from other agent harnesses, kept as
references rather than something we run verbatim:

- `system-prompts-and-models-of-ai-tools/` — submodule of leaked/published system
  prompts from various AI tools.
- `deer-flow/` — portable prompt templates extracted from
  [bytedance/deer-flow](https://github.com/bytedance/deer-flow) 2.0 (MIT): the
  lead-agent "super agent" system prompt, a subagent decompose/delegate/synthesize
  orchestrator, and structured memory-management prompts. See its `README.md`.

## Live prompts

The regular Markdown files in `live-prompts/` are the canonical source for
every agent. Each file is also a valid Codex skill and must include both `name`
and `description` in its YAML frontmatter.

Run `scripts/install.sh` to expose each prompt through the agent's native
surface:

- Pi: `~/.pi/agent/prompts/<name>.md`, invoked as `/<name>`.
- Claude: `~/.claude/commands/<name>.md`, invoked as `/<name>`.
- opencode: `~/.config/opencode/command/<name>.md`, invoked as `/<name>`.
- Codex: a regular copy at `~/.codex/skills/<name>/SKILL.md`, invoked with
  `$<name>` or selected from the `/` menu.

Claude, Pi, and opencode receive symlinks to the canonical files. Codex receives
regular installed copies because its skill loader does not discover a symlinked
`SKILL.md`. Rerun `scripts/install.sh` after editing a live prompt to refresh
the Codex copies.

For Pi you can still pass a prompt directory explicitly:

```bash
pi --prompt-template prompts/live-prompts
```

To add a live prompt, create one canonical file and rerun the installer:

```bash
# Write prompts/live-prompts/<name>.md with name and description frontmatter.
scripts/install.sh
```
