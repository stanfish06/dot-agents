# Prompts

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

Reusable during-session workflows live canonically as skills under
`skills/<name>/SKILL.md`. The matching files in `live-prompts/*.md` are thin
compatibility adapters that invoke those skills. Run `scripts/install.sh` to
install the skills and symlink each adapter into the agent-specific live prompt
surface:

- Pi: `~/.pi/agent/prompts/<name>.md`, invoked as `/<name>`.
- Claude: `~/.claude/commands/<name>.md`, invoked as `/<name>`.
- opencode: `~/.config/opencode/command/<name>.md`, invoked as `/<name>`.
- Codex desktop: the installed skills appear in the `/` menu.
- Codex CLI/IDE: `~/.codex/prompts/<name>.md`, invoked as
  `/prompts:<name>`.

For Pi you can still pass a prompt directory explicitly:

```bash
pi --prompt-template prompts/live-prompts
```

Codex custom prompts are deprecated, so the desktop app uses the skill directly
while the CLI/IDE adapter preserves the older shortcut. Because every live
prompt now depends on its matching skill, use `--skip-skills` only when those
skills were installed previously.
