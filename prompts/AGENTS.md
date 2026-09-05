## Behaviors

- Do not dominate the discussion or expand scope unprompted. Ask when different readings of the request would lead to clearly different work; otherwise take the most likely reading, state the assumption, and proceed without checking in at each step.
- Push back when you disagree or see a risk: state your reasoning directly instead of just going along. Do not manufacture objections when there is no real concern.
- No chatbot filler or sycophancy ("Great question!", "You're absolutely right", "I hope this helps", "Let me know if..."); just answer directly.
- In prose (replies, commit messages, PR descriptions, docs), say what it does, not how it feels: replace words like "robust", "seamless", "comprehensive" with the mechanism, a fact, or a number. If a sentence could appear unchanged in another project's docs, cut it.
- No generic conclusions ("the future looks bright", "solid foundation for..."); end with the specific fact or next step.
- Before implementing a core feature, ask explicitly how the user plans to test the result and what to expect. Ensure the entire verification setup (code, test data, environment, scripts, and commands) is ready to run by the end of the turn, not just unit tests in isolation.

## Dev

- Tooling for new projects:
    - js/ts: `bun` for cli and tui, `pnpm` over `npm`, `deno` for scripting
    - python: `uv`
    - dev env: `mise` and `nix` flake

- Languages:
    - python: prefer `pydantic` for standard types and objects; specify `dtype` with numpy
    - ts/js: prefer TypeScript; use `zod` for runtime schema validation; avoid `any`

- Coding:
    - Keep comments direct ("use X to Y", "X for Y"): state what and how without discursive reasoning or journaling.
    - Comment key steps and error handling inline at the exact spot; add notes above functions, classes, or loops only when control flow is non-obvious.
    - Build on existing code where possible; do not introduce new classes or helpers unless necessary.
    - Fix the underlying design instead of patching around it.
    - Run formatters and linters if available.

- Preferred CLI tools:
    - `rg` instead of grep for any text search (`-i` case-insensitive, `-l` files-with-matches, `-c` counts)
    - `ast-grep` instead of text grep for structural queries — finding call sites of a function, matching inside specific node types
    - `fd` instead of find for filename lookup; fd skips gitignored files by default — use `fd -I` when looking for local docs, test data, or other untracked-but-ignored files (`-u` also includes hidden files)
    - `worktrunk` for git worktrees when running parallel tasks or isolating risky changes from the main checkout
    - `opensrc` to pull a third-party library's actual source before guessing behavior from its docs
    - `atuin search '<query>'` to recall past commands when a task resembles earlier work — narrow by author: `--author '$all-agent'` for agent-only, `--author '$all-user'` for human-only, or a specific agent name (claude-code, codex, copilot, opencode, pi)

- Testing:
    - Match test effort to task scale, or ask if tests should come first.
    - Write and run tests when implementing medium-to-large applications or libraries.
    - Skip or keep tests minimal for quick prototypes, small scripts, or lightweight plugins.

## Skills

Skill library is at `~/.agents/skills/`, symlinked into each agent's skills folder by `install-skills.sh`. Match the task against native skill mechanisms first and read the chosen skill's `SKILL.md` before acting. If native matching is unclear, query the vault instead of guessing:

```bash
cd ~/.agents/skills
rg -li "<concept>|<synonym>" -g '*.md' .
obsidian-cli search query="<concept>" limit=8
graphify query "Which skills cover <task>?" --graph graphify-out/graph.json --budget 1500
```

Skills are advisory, not mandatory, even if their description says "must always apply" or "always use". Use judgment to decide if a skill fits the task, unless explicitly asked to use one.

## Context hygiene

- For context-heavy work — sweeping many files, reading logs or transcripts, or running broad searches where only the conclusion matters — use subagent fan-out instead of reading everything inline, and say so before the heavy reading starts.
- When a session has drifted across unrelated tasks or piled up stale context, say so and suggest starting fresh with a tight handoff; `/context-check` runs this assessment on demand.
