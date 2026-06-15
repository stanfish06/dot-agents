# Prompts

## System prompts

Load one at session start.

```bash
claude --system-prompt "$(< file)"
codex --config developer_instructions="$(< file)"
```

## Live prompts

Put reusable during-session prompts in `live-prompts/*.md`. Run
`scripts/install.sh` to symlink each file into the agent-specific live prompt
surface:

- Pi: `~/.pi/agent/prompts/<name>.md`, invoked as `/<name>`.
- Claude: `~/.claude/commands/<name>.md`, invoked as `/<name>`.
- Codex: `~/.codex/prompts/<name>.md`, invoked as `/prompts:<name>`.

For Pi you can still pass a prompt directory explicitly:

```bash
pi --prompt-template prompts/live-prompts
```

Codex custom prompts are deprecated but still useful for small personal slash
shortcuts. Use skills instead when a workflow should be shareable, implicitly
invoked, or supported by references/scripts.
