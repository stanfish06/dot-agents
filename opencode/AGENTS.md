# AGENTS.md — operating guide for opencode

You have access to a curated library of agent skills. opencode auto-loads
skills from three locations:

- `~/.config/opencode/skills/` — opencode-native global skills
- `~/.claude/skills/` — shared Claude Code skills
- `~/.agents/skills/` — the central skill vault (symlinked from the
  `stanfish06/my-skills` repo, 390+ skills)

A *skill* is a folder with a `SKILL.md` holding battle-tested instructions
for a specific tool, library, or workflow. **Using a relevant skill is
faster and more reliable than improvising.**

## Skill-first workflow

Before starting any substantive task, actively check whether a relevant
skill exists. Do not rely only on memory or improvisation when a skill
might cover the work. If a relevant skill exists for the task category,
invoke it; a verbal `Skill check` line is not a substitute for using the
skill.

1. Use opencode's native skill list. Match the user's task to available
   skill names and descriptions, then invoke the best matching skill. Do
   not bypass invocation merely because the task looks small, simple, or
   familiar.
2. At the start of your response or first status update, state the
   outcome: `Using skill: <name>` / `Using skills: <names>` / `Skill
   check: no matching skill found`. Only say `Skill check: no matching
   skill found` after you have failed to identify a relevant skill.
3. If a skill is chosen, follow its full `SKILL.md` instructions before
   acting. If multiple skills apply, use the smallest useful set and say
   the order.
4. If native matching is unclear, query the vault instead of guessing:
   ```bash
   cd ~/.agents/skills
   rg -li "<concept>|<synonym>" -g '*.md' .
   obsidian-cli search query="<concept>" limit=8
   graphify query "Which skills cover <task>?" --graph graphify-out/graph.json --budget 1500
   ```
5. Skip the skill check only for truly trivial chat or one-line factual
   tasks. Coding, debugging, review, documentation, repo maintenance,
   data analysis, scientific workflows, browser automation, and
   external-tool work are not trivial. For those categories, if a
   relevant skill exists, use it even for a tiny diff, a short question,
   or a quick sanity check.
6. If no skill fits, say so briefly and continue with the best available
   method.

## Common skill triggers

- For bug reports, failed tests, surprising behavior, or root-cause work,
  use `systematic-debugging`.
- For code or PR review, use `code-review-and-quality`, `check-pr`, or
  `greploop` as appropriate.
- For implementation work, consider `brainstorming`, `writing-plans`,
  `test-driven-development`, and `verification-before-completion`.
- For unfamiliar repositories or documentation sets, use `graphify`.
- For unfamiliar dependencies, use `opensrc` or source-grounding skills
  before relying on remembered APIs.
- For creating or editing skills, use `skill-builder` or `writing-skills`.
- For any Word (`.docx`), Excel (`.xlsx`/`.csv`), or PowerPoint (`.pptx`) task,
  invoke `officecli-docx`, `officecli-xlsx`, or `officecli-pptx` before acting;
  use `officecli` for general or cross-format work. Also load the matching
  specialized skill for academic papers, dashboards, financial models, pitch
  decks, fillable Word forms, or Morph presentations. Follow its inherited
  base-skill, help-first, and delivery/visual-validation requirements, and run
  `officecli help` instead of guessing syntax or properties.

## Context hygiene

- For context-heavy work — sweeping many files, reading logs or
  transcripts, multi-repo exploration, or broad searches where you only
  need the conclusion — proactively propose or use subagent fan-out (the
  `dispatching-parallel-agents` / `subagent-driven-development` skills)
  instead of reading everything inline, so the main thread's context
  stays clean. Raise the option before the heavy reading, not after.
- When a session has clearly drifted across unrelated tasks or piled up
  stale context, say so and suggest starting fresh with a tight handoff.
  The `/context-check` live prompt runs this assessment on demand.

## Establishing context

- **Read a dependency's real code** instead of guessing its API:
  ```bash
  rg "createServer" $(opensrc path express)
  cat $(opensrc path pypi:fastapi)/fastapi/routing.py
  ```
- **Understand an unfamiliar codebase** by turning it into a knowledge
  graph with `graphify`, then query it.
- **For this skills vault itself**, query the local graph when present:
  ```bash
  cd ~/.agents/skills
  graphify query "How is the skill library organized?" --graph graphify-out/graph.json
  ```

## Default loop for a coding task

1. **Skill check** — is there a skill for this? If yes, read its
   `SKILL.md` and follow it.
2. **Context** — `opensrc`/`graphify` the relevant dependency or
   codebase; read real code.
3. **Plan** — for anything multi-step, `brainstorming` → `writing-plans`.
4. **Implement** — `test-driven-development`; isolate with
   `using-git-worktrees` if risky.
5. **Verify** — `verification-before-completion`: run tests/lint, show
   the output.
6. **Review** — `requesting-code-review`, or `check-pr`/`greploop` on the
   PR.

## graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) — any input to
  knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with
`skill: "graphify"` before doing anything else.
