# Codex Live Prompt Skills Design

## Problem

`dot-agents` installs `prompts/live-prompts/*.md` into native command
directories for Claude, Pi, opencode, and Codex. The Codex CLI and IDE extension
still load custom prompts from `~/.codex/prompts`, but the Codex desktop app does
not expose that deprecated prompt surface. The app does expose enabled skills in
its `/` menu.

## Decision

Promote each live prompt to an explicit-only skill in the `skills/` submodule:

- `check-repo-status`
- `context-check`
- `review-git-changes`

The skill `SKILL.md` is the canonical workflow. Each skill also carries
`agents/openai.yaml` with `policy.allow_implicit_invocation: false`, preserving
the current live-prompt contract that the workflow runs only when the user
chooses it.

The existing `prompts/live-prompts/*.md` files remain as compatibility adapters
for Claude, Pi, opencode, and the Codex CLI/IDE. Each adapter explicitly asks the
agent to invoke and follow the corresponding installed skill. This keeps the
legacy command names while avoiding a second copy of the workflow instructions.

## User Experience

- Codex desktop: type `/` and select the named skill.
- Codex CLI/IDE: continue using `/prompts:<name>`.
- Claude, Pi, and opencode: continue using `/<name>`.

No existing command is removed. Users who install only selected components must
install skills before using the compatibility prompt adapters.

## Installation and Data Flow

The existing installer order remains authoritative:

1. Initialize and install the `skills/` submodule.
2. Install agent configuration.
3. Symlink the compatibility prompt adapters into each native prompt directory.

Selecting a Codex desktop slash-menu entry invokes the installed skill directly.
Selecting a legacy prompt command injects the small adapter, which tells the
agent to invoke the same skill. Both routes therefore converge on one canonical
workflow.

`--skip-skills` remains supported, but its help text and prompt documentation
must make clear that skill-backed live prompts require the skills to have
already been installed.

## Repository Boundaries

The canonical skills belong in `stanfish06/my-skills`, the `skills/` submodule,
because this repository requires reusable skills to live there. The
`dot-agents` change updates the submodule pointer, compatibility adapters,
installer messaging, and prompt documentation.

This produces two dependent pull requests:

1. Add and index the three skills in `stanfish06/my-skills`.
2. Update `stanfish06/dot-agents` to consume them and document the Codex app
   surface.

## Failure Handling

- A missing canonical skill is detected by repository validation before release.
- The installer reports that `--skip-skills` assumes the required skills are
  already installed.
- Compatibility adapters name the exact skill, so a harness that cannot find it
  fails visibly instead of silently running a stale embedded copy.
- Codex skill metadata disables implicit invocation to prevent read-only checks
  or review workflows from running unexpectedly.

## Verification

### Skills repository

- Run the vault build to regenerate wrapper notes, maps, index, taxonomy, and
  provenance outputs.
- Run the vault's targeted skill validator for all three new skills.
- Verify each `agents/openai.yaml` parses and disables implicit invocation.
- Run `git diff --check`.

### dot-agents repository

- Validate the three compatibility adapters reference existing skill names.
- Run `bash -n scripts/install.sh`.
- Run `scripts/install.sh --dry-run --skip-skills` and inspect all prompt
  targets.
- Run `git diff --check`.
- After installation, reload Codex skills or start a new thread and verify the
  three entries appear in the `/` menu.

## Non-Goals

- Restoring deprecated custom-prompt support inside the Codex desktop app.
- Preserving `/prompts:<name>` syntax in the desktop app.
- Packaging these three personal workflows as a public Codex plugin.
- Changing the workflow behavior beyond the metadata needed to make each prompt
  a valid skill.
