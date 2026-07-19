#!/usr/bin/env bash
# Regression test for the Codex UserPromptSubmit hook output contract.

set -euo pipefail

payload="$(printf '%s' '{"hook_event_name":"UserPromptSubmit","prompt":"Implement {feature}"}' \
  | bash hooks/codex-skill-check-reminder.sh)"

PAYLOAD="$payload" node <<'NODE'
const payload = JSON.parse(process.env.PAYLOAD);
const output = payload.hookSpecificOutput;

if (!output || output.hookEventName !== 'UserPromptSubmit') {
  throw new Error('missing UserPromptSubmit hookSpecificOutput');
}

if (typeof output.additionalContext !== 'string') {
  throw new Error('additionalContext must be a string');
}

if (!output.additionalContext.startsWith('[skill-first reminder]')) {
  throw new Error('additionalContext is missing the skill-first reminder');
}

console.log('codex skill-check UserPromptSubmit JSON payload OK');
NODE
