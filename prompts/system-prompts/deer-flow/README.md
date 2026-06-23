# deer-flow prompts

Reusable prompt templates extracted from [bytedance/deer-flow](https://github.com/bytedance/deer-flow)
2.0 — an open-source "super agent harness" that orchestrates sub-agents, memory,
and sandboxes. deer-flow itself is a full application (Python/LangGraph backend +
Next.js frontend); these are just the **portable prompt artifacts** worth keeping
as references for our own agent surfaces.

- **License:** deer-flow is MIT (Copyright (c) 2025 Bytedance Ltd.; 2025-2026
  DeerFlow Authors). These extracts are derivative text under that license.
- **Source path (at time of import):**
  `backend/packages/harness/deerflow/agents/` — `lead_agent/prompt.py` and
  `memory/prompt.py`.
- **Imported:** 2026-06-23, from `main`.

## Files

| File | What it is | Upstream source |
|---|---|---|
| `lead-agent-system-prompt.md` | The full lead-agent ("super agent") system prompt template: role, system-context confidentiality, thinking style, a strict CLARIFY → PLAN → ACT clarification system, skill system + skill self-evolution, working-directory conventions, response style, citations, and critical reminders. | `lead_agent/prompt.py` (`SYSTEM_PROMPT_TEMPLATE` + the section builders it composes) |
| `subagent-orchestrator.md` | The `<subagent_system>` block: a decompose → delegate → synthesize orchestration pattern with explicit parallel-batch discipline and a hard per-turn concurrency cap. | `lead_agent/prompt.py` (`_build_subagent_section`) |
| `memory-prompts.md` | Two memory-management prompts: `MEMORY_UPDATE_PROMPT` (reflect on a conversation and update a structured user-memory profile) and `FACT_EXTRACTION_PROMPT` (extract typed, confidence-scored facts from a single message). Relevant to issue #9 (persisting conversation history). | `memory/prompt.py` |

## Placeholder convention

The upstream prompts are Python `str.format` templates. Dynamic values are kept
as `{{double-brace}}` tokens so the text stays a usable template without colliding
with literal braces. The common ones:

- `{{agent_name}}` — agent display name (default `DeerFlow 2.0`).
- `{{n}}` — max concurrent `task`/subagent calls per turn (upstream default 3).
- `{{soul}}` — optional per-agent personality block (`<soul>…</soul>`).
- `{{available_subagents}}` — runtime-generated list of subagent types.
- `{{current_memory}}`, `{{conversation}}`, `{{message}}` — memory-prompt inputs.

Sections that deer-flow injects conditionally (skill system, self-update, ACP,
deferred tools) are inlined here with a note where they would be toggled, so the
template reads as a complete prompt rather than a skeleton.
