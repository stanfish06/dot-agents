#!/usr/bin/env bash
# UserPromptSubmit hook: re-inject the Codex skill-check reminder on every prompt.
#
# The skill rules live in prompts/AGENTS.md (## Skills); this keeps the check in
# view for complex tasks. UserPromptSubmit context is returned using Codex's
# structured hook output contract.
set -euo pipefail

message="$(cat <<'EOF'
[skill-first reminder] Before substantive work (coding, debugging, code/PR
review, docs, repo maintenance, data analysis, scientific workflows, browser
automation, external-tool work), run the skill check: match the task to an
available skill and, if one fits, read and follow its SKILL.md before acting.
State the outcome at the top of your reply - `Using skill: <name>` /
`Using skills: <names>` / `Skill check: no matching skill found`. Run the
check on any multi-step task, even one that looks familiar. Skip it only for
single-step edits, quick factual questions, and chat.
EOF
)"

jq -n --arg additional_context "$message" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: $additional_context
  }
}'
