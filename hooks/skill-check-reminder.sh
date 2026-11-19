#!/usr/bin/env bash
# UserPromptSubmit hook: re-inject the skill-check reminder on every prompt.
#
# The skill rules live in prompts/AGENTS.md (## Skills); this keeps the check in
# view for complex tasks. For UserPromptSubmit, stdout on exit 0 is appended to
# context.
set -euo pipefail

cat <<'EOF'
[skill-first reminder] Before substantive work (coding, debugging, code/PR
review, docs, repo maintenance, data analysis, scientific workflows, browser
automation, external-tool work), run the skill check: match the task to an
available skill and, if one fits, invoke it via the Skill tool before acting.
State the outcome at the top of your reply - `Using skill: <name>` /
`Using skills: <names>` / `Skill check: no matching skill found`. Run the
check on any multi-step task, even one that looks familiar. Skip it only for
single-step edits, quick factual questions, and chat.
EOF
