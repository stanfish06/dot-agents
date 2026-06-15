# System prompts
Load one at start
```bash
claude --system-prompt "$(< file)"
codex --config developer_instructions="$(< file)"
```

# Live prompts
Inject in a session
- pi agent
    - `pi --prompt-template <path>`
    - then, `/<prompt template name>` (e.g. `/review-git-changes`)
