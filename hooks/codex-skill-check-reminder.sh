#!/usr/bin/env bash
# UserPromptSubmit hook: re-inject the Codex skill-first workflow reminder.
#
# The skill-first guidance lives in AGENTS.md, but static instructions can be
# easy to gloss over on a task that looks small or familiar. This hook fires on
# each Codex user prompt so the skill check stays salient. For UserPromptSubmit,
# plain text on stdout is added as extra developer context.
set -euo pipefail

cat <<'EOF'
[skill-first reminder] Before substantive work (coding, debugging, code/PR
review, docs, repo maintenance, data analysis, scientific workflows, browser
automation, external-tool work), run the SKILL CHECK FIRST: inspect the
available skill names/descriptions and, if one fits, read and follow its
SKILL.md before acting. State the outcome at the top of your reply -
`Using skill: <name>` / `Using skills: <names>` / `Skill check: no matching
skill found`. Do not skip this because the task looks small, simple, or
familiar. Skip only for truly trivial chat or a one-line factual answer.
EOF
