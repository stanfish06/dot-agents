# Claude operating guide

You have access to a large personal skill library in `~/.claude/skills/`, mostly
symlinked from `~/.agents/skills/`. A skill is a directory with `SKILL.md` that
contains reusable instructions for a specific tool, library, domain, or workflow.

## Skill-first workflow

Before starting any substantive task, actively check whether a relevant skill
exists. Do not rely only on memory or improvisation when a skill might cover the
work. If a relevant skill exists for the task category, invoke it; a verbal
`Skill check` line is not a substitute for using the skill.

1. Use Claude Code's native skill list first. Match the user's task to available
   skill names and descriptions, then invoke the best matching skill. Do not
   bypass invocation merely because the task looks small, simple, or familiar.
2. At the start of your response or first status update, state the outcome:
   `Using skill: <name>` / `Using skills: <names>` / `Skill check: no matching
   skill found`. Only say `Skill check: no matching skill found` after you have
   failed to identify a relevant skill.
3. If a skill is chosen, follow its full `SKILL.md` instructions before acting.
   If multiple skills apply, use the smallest useful set and say the order.
4. If native matching is unclear, query the vault instead of guessing:
   ```bash
   cd ~/.agents/skills
   rg -li "<concept>|<synonym>" -g '*.md' .
   obsidian-cli search query="<concept>" limit=8
   graphify query "Which skills cover <task>?" --graph graphify-out/graph.json --budget 1500
   ```
5. Skip the skill check only for truly trivial chat or one-line factual tasks.
   Coding, debugging, review, documentation, repo maintenance, data analysis,
   scientific workflows, browser automation, and external-tool work are not
   trivial. For those categories, if a relevant skill exists, use it even for a
   tiny diff, a short question, or a quick sanity check.
6. If no skill fits, say so briefly and continue with the best available method.

## Common skill triggers

- For bug reports, failed tests, surprising behavior, or root-cause work, use
  `systematic-debugging`.
- For code or PR review, use `code-review-and-quality`, `check-pr`, or
  `greploop` as appropriate.
- For implementation work, consider `brainstorming`, `writing-plans`,
  `test-driven-development`, and `verification-before-completion`.
- For unfamiliar repositories or documentation sets, use `graphify`.
- For unfamiliar dependencies, use `opensrc` or source-grounding skills before
  relying on remembered APIs.
- For creating or editing skills, use `skill-builder` or `writing-skills`.

## Context hygiene

- For context-heavy work - sweeping many files, reading logs or transcripts,
  multi-repo exploration, or broad searches where you only need the conclusion -
  proactively propose or use subagent fan-out (the `Explore` agent or the
  `dispatching-parallel-agents` skill) instead of reading everything inline, so
  the main thread's context stays clean. Raise the option before the heavy
  reading, not after.
- When a session has clearly drifted across unrelated tasks or piled up stale
  context, say so and suggest starting fresh with a tight handoff. The
  `/context-check` live prompt runs this assessment on demand.

## graphify

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
