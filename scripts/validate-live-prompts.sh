#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_DIR="$ROOT/prompts/live-prompts"
SKILL_DIR="$ROOT/skills"

names=()
if [ "$#" -gt 0 ]; then
  names=("$@")
else
  for prompt in "$PROMPT_DIR"/*.md; do
    [ -e "$prompt" ] || continue
    names+=("$(basename "$prompt" .md)")
  done
fi

[ "${#names[@]}" -gt 0 ] || {
  echo "ERROR: no live prompts found in $PROMPT_DIR" >&2
  exit 1
}

for name in "${names[@]}"; do
  prompt="$PROMPT_DIR/$name.md"
  skill="$SKILL_DIR/$name/SKILL.md"
  metadata="$SKILL_DIR/$name/agents/openai.yaml"

  [ -f "$prompt" ] || {
    echo "ERROR: missing live prompt: $prompt" >&2
    exit 1
  }
  [ -f "$skill" ] || {
    echo "ERROR: missing canonical skill: $skill" >&2
    exit 1
  }
  [ -f "$metadata" ] || {
    echo "ERROR: missing Codex skill metadata: $metadata" >&2
    exit 1
  }
  grep -Fxq "name: $name" "$skill" || {
    echo "ERROR: skill name does not match prompt: $name" >&2
    exit 1
  }
  grep -Fq 'allow_implicit_invocation: false' "$metadata" || {
    echo "ERROR: live prompt skill allows implicit invocation: $name" >&2
    exit 1
  }
  grep -Fq 'Use the `'"$name"'` skill' "$prompt" || {
    echo "ERROR: prompt does not invoke canonical skill: $name" >&2
    exit 1
  }
done

echo "OK: selected live prompts map to explicit-only skills"
