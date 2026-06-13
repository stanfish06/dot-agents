#!/usr/bin/env bash
# UserPromptSubmit hook: re-inject the skill-first workflow reminder.
#
# The skill-first guidance lives in CLAUDE.md, but static instructions are easy
# to gloss over on a task that "looks small or familiar" - exactly the trap the
# guidance warns about. This hook fires on every user prompt so the skill check
# stays salient. For UserPromptSubmit, stdout on exit 0 is appended to context.
set -euo pipefail

cat <<'EOF'
[skill-first reminder] Before substantive work (coding, debugging, code/PR
review, docs, repo maintenance, data analysis, scientific workflows, browser
automation, external-tool work), run the SKILL CHECK FIRST: match the task to
an available skill and, if one fits, invoke it via the Skill tool *before*
acting. State the outcome at the top of your reply - `Using skill: <name>` /
`Using skills: <names>` / `Skill check: no matching skill found`. Do not skip
this because the task looks small, simple, or familiar. Skip only for truly
trivial chat or a one-line factual answer.
EOF
