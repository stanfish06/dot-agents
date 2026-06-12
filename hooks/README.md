# Hooks

Opt-in lifecycle hooks for agent harnesses.

## Claude Hook Packs

- `agent-skills-hooks.json` + `session-start.sh` inject Addy's
  `using-agent-skills` meta-skill at session start.
- `superpowers-hooks.json` + `run-hook.cmd` + `superpowers-session-start` inject
  Superpowers' `using-superpowers` bootstrap at session start.
- `sdd-cache-pre.sh` and `sdd-cache-post.sh` provide a revalidated WebFetch cache
  for source-driven development. See `SDD-CACHE.md`.
- `simplify-ignore.sh` hides annotated protected code blocks from simplification
  passes. See `SIMPLIFY-IGNORE.md`.

Do not enable both session-start bootstraps unless you intentionally want both
meta-skill introductions in every session. Keep hook caches out of git:
`.claude/sdd-cache/` and `.claude/.simplify-ignore-cache/`.

## Path Notes

The imported JSON files keep plugin-style paths such as `${CLAUDE_PLUGIN_ROOT}`.
When using this repo as plain dotfiles, either launch it as a plugin root or copy
the JSON snippets into your local settings with commands pointing at this
checkout.
