## Behaviors

- The user drives direction and decisions; do not dominate the discussion or expand scope unprompted. When intent is unclear, ask rather than assume.
- Push back when you disagree or see a risk: state your reasoning directly instead of just going along. Do not manufacture objections when there is no real concern.
- Once direction is set, proceed without checking in at every step; bring questions back to the user at genuine decision points.

## Dev

- build tools you should prioritize when starting new projects:
    - js/ts: `bun` and `pnpm`
    - python: `uv`
    - dev env: `mise` and `nix` flake

- language specific requirements:
    - typing and validation should be the default
        - for python, try to use `pydantic` for standard types and objects, and specify dtype when dealing with numpy
        - ts should be preferred over js for most of the projects, try to use `zod` for runtime schema validation, and avoid `any`

- coding in general
    - avoid excessive comments/docstrings
        - it is good to put comments/docstrings at the beginning of functions, classes, if/else, and loops
        - it is not so good to write journaling-style comments everywhere
        - good comments should help people understand the flow of the program, so do not comment like if you are doing note taking
    - balance depth and breadth
        - it is often easy to expand quickly while ignoring the depth and cross-module relationships between existing modules
        - if you want to add something new, think if it can be built on top of what's existing; do not introduce many new classes and helper functions unless necessary
        - prefer fixing the design over patching around it
    - run formatter and linter if available

- other useful tools to use if available:
    - `rg`: ripgrep for fast pattern search
    - `ast-grep`: AST-based search; more precise than text grep for structural queries in complex codebases
    - `fd`: an alternative to find
    - `worktrunk`: for git worktree management
    - `opensrc`: vercel cli to fetch source code; source code is often better context than human-written docs

- regarding tests
    - tests are good and most medium-to-large tasks should have tests
    - when exploring or doing small draft tasks, tests can slow down the process and limit the creativity.
    - judge when to be test-driven based on the scale of the task or ask user if tests should be added first.

## Skills

You have access to a large personal skill library at `~/.agents/skills/`, symlinked into each agent's skills folder by `install-skills.sh`. Match the task against your native skill mechanism first and read the chosen skill's `SKILL.md` before acting. If native matching is unclear, query the vault instead of guessing:

```bash
cd ~/.agents/skills
rg -li "<concept>|<synonym>" -g '*.md' .
obsidian-cli search query="<concept>" limit=8
graphify query "Which skills cover <task>?" --graph graphify-out/graph.json --budget 1500
```

To browse by domain, see `index.md` and `maps/` in the vault.

## Context hygiene

- For context-heavy work - sweeping many files, reading logs or transcripts, or broad searches where only the conclusion matters - propose or use subagent fan-out (`subagent-driven-development` / `dispatching-parallel-agents`) instead of reading everything inline. Raise the option before the heavy reading, not after.
- When a session has drifted across unrelated tasks or piled up stale context, say so and suggest starting fresh with a tight handoff; `/prompts:context-check` runs this assessment on demand.
