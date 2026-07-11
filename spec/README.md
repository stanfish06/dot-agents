# Spec tooling landscape

This folder is reserved for **spec-driven development (SDD)** experiments that
belong with agent configuration: how we write, store, and drive work from
specifications before (and after) code.

Today this is a **catalog and notes** area. Later it may hold scripts, templates,
or harness glue that steers the local `/spec` → `/plan` → `/build` path (or
another front door) without forcing a third-party product into every repo.

---

## Why specs matter for agents

Coding agents are strong at implementation and weak at remembering *intent*
across sessions. Specs turn chat intent into **repo-local artifacts** agents can
re-read: outcomes, boundaries, design choices, tasks, and verification.

Three maturity levels show up across tools (adapted from common SDD writing,
including Martin Fowler / Tessl-style framing):

| Level | Idea | Typical tools |
| --- | --- | --- |
| **Spec-first** | Spec guides a task, then code becomes the real source of truth | Kiro (lightweight mode), ad-hoc `SPEC.md` |
| **Spec-anchored** | Specs stay in the repo and gate plan → tasks → implement | Spec Kit, OpenSpec, BMAD, local `/spec` stack |
| **Spec-as-source** | Spec is primary; generated code is closer to a compile artifact | Tessl (strong form) |

This repo already has an anchored path via skills (`spec-driven-development`,
`planning-and-task-breakdown`, `/spec`, `/plan`, `/build`). The tools below are
the mainstream *products* people adopt for the same job.

---

## Mainstream tools (catalog)

### 1. OpenSpec (Fission-AI)

- **Repo / site:** [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) · [openspec.dev](https://openspec.dev/)
- **Stack:** Node / npm (`@fission-ai/openspec`), slash commands like `/opsx:propose`
- **License:** MIT

**Philosophy**

Lightweight, **change-centric** SDD. Agree in files before code; stay fluid
(artifacts are enablers, not hard phase gates). Optimized for **brownfield**:
describe *deltas* against current behavior, not a full product rewrite. Archive
folds finished work back into living system specs.

**How it structures a project**

```text
openspec/
  specs/                      # living truth (by domain)
    auth/
    payments/
  changes/
    add-dark-mode/            # one unit of work
      proposal.md             # why
      specs/                  # delta: ADDED / MODIFIED / REMOVED
      design.md               # how
      tasks.md                # steps
    archive/
      2025-01-23-add-dark-mode/
```

**Loop:** `/opsx:explore` → `/opsx:propose` → `/opsx:apply` → `/opsx:archive`  
Optional **Stores** (beta): plan in a separate shared repo for multi-repo teams.

---

### 2. Spec Kit (GitHub)

- **Repo / site:** [github/spec-kit](https://github.com/github/spec-kit) · [docs](https://github.github.io/spec-kit/)
- **Stack:** Python / `uv` (`specify` CLI), `/speckit.*` commands or skills mode
- **License:** MIT

**Philosophy**

**Specifications become executable drivers** of work, not throwaway scaffolding.
Strong **phased** workflow with a project **constitution** (principles) that
downstream specs inherit. Greenfield-friendly; lots of intermediate artifacts
for clarity, compliance, and multi-agent portability. Heavy ecosystem of
extensions, presets, and role **bundles**.

**How it structures a project**

```text
.specify/
  memory/
    constitution.md            # project principles (governance)
  scripts/
  templates/
specs/
  001-create-taskify/         # numbered feature package
    spec.md                   # what / user stories / requirements
    plan.md                   # tech approach
    tasks.md                  # actionable checklist
    research.md               # optional
    data-model.md             # optional
    contracts/                # optional API contracts
```

**Loop:**  
`/speckit.constitution` → `/speckit.specify` → `/speckit.clarify` →  
`/speckit.plan` → `/speckit.tasks` → (`/speckit.analyze`) → `/speckit.implement`  
Optional: `/speckit.checklist`, `/speckit.converge`, `/speckit.taskstoissues`.

---

### 3. Amazon Kiro

- **Site:** [kiro.dev](https://kiro.dev/)
- **Stack:** Product IDE / agent environment (AWS-associated), not a portable
  open CLI in the same sense as Spec Kit / OpenSpec

**Philosophy**

**Spec-first inside a full coding product.** Requirements → design → tasks as a
tight IDE loop so the agent is steered by structured artifacts rather than free
chat. Stronger product lock-in; less “drop into any agent.” Fowler-style
writeups often place it on the lighter **spec-first** end: great for a story or
feature session, less emphasis on multi-year living domain specs than OpenSpec’s
archive model.

**How it structures work (typical)**

```text
# IDE-managed (names vary by version / template)
requirements.md   # or requirements/  — user stories, acceptance
design.md         # technical approach
tasks.md          # implementation checklist
```

Artifacts are the working set for the current feature; the IDE agent executes
against them rather than only against chat history.

---

### 4. BMAD-METHOD (BMad)

- **Repo:** [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- **Stack:** Multi-agent / multi-persona workflow (slash commands / agent roles)

**Philosophy**

**Agentic agile**, not just a single “write a SPEC.md” skill. Specialized
personas (PM, architect, dev, etc.) and full-lifecycle elicitation: PRD-style
planning can merge into normal project `docs/`, with a lighter **Quick Flow**
that skips straight toward implementation. Higher ceremony than OpenSpec; more
about *who* thinks and *how* requirements are elicited than about delta merge
semantics.

**How it structures a project (typical)**

```text
docs/                         # often merges planning into ordinary docs
  prd.md                      # product requirements (mode-dependent)
  architecture.md             # optional / role-driven
  # epics / stories / tasks depending on mode
# Plus BMad agent/command configuration in the agent harness
```

**Loop (conceptual):** create PRD / elicit → architecture → stories/tasks →
implement, with course-correction workflows for complex work. Quick Flow short-
circuits planning for small changes.

---

### 5. GSD — Get Shit Done

- **Repo:** [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)
- **Stack:** Meta-prompting / context-engineering system, often Claude Code–centric

**Philosophy**

**Execution and context control** first: less “beautiful living specs,” more
“given a solid plan, keep the agent shipping without context rot.” Treats
spec/plan as fuel for long autonomous runs. Popular with solo Claude Code users
who want a harness more than an enterprise requirements system.

**How it structures work**

Varies by version; generally **plan + task state + execution prompts** wired as
skills/commands rather than a single canonical `openspec/` tree. Specs exist to
drive uninterrupted implementation more than to become a permanent product
model.

---

### 6. Tessl

- **Site:** [tessl.io](https://tessl.io/)
- **Stack:** Platform / tooling around **specs as primary artifacts**

**Philosophy**

**Spec-as-source (strong form):** intent is written in structured, testable
spec language; implementation is generated and treated more like output of a
compiler than the long-term human-edited center of gravity. Closest of the
mainstream names to “specs replace code as the source of truth.”

**How it structures work**

Product-specific: emphasis on **durable, testable specs** and tracking progress
against them, not on a public `propose/apply/archive` folder convention like
OpenSpec. See Tessl’s own SDD writing for the maturity framing (spec-first vs
spec-anchored vs spec-as-source).

---

### 7. Taskmaster AI

- **Presence:** Commonly listed alongside GSD / Spec Kit / OpenSpec in 2026 SDD
  roundups (MCP-oriented task/context systems)
- **Stack:** Task graph + MCP / agent integration

**Philosophy**

**Context guardian** for large projects: persist and serve tasks, status, and
dependencies so agents don’t lose the thread mid-epic. Spec/plan quality
matters, but the product pitch is **task memory and continuity**, not living
domain requirements.

**How it structures work**

Task-centric store (tasks, status, deps) exposed to agents via MCP or similar —
orthogonal to OpenSpec-style domain `specs/` trees. Often paired with a
separate planning step rather than replacing it.

---

### 8. Agent OS

- **Mentioned as** an earlier structured “agent OS / instructions” approach in
  SDD discussions (often contrasted with Spec Kit’s later ecosystem push)

**Philosophy**

Centralize **agent operating instructions and structured workflows** so agents
aren’t driven by sprawling one-off prompts. Overlaps SDD and general agent
harness design (closer to “how the agent is configured” than only “feature
spec folders”).

**How it structures work**

Harness-oriented: conventions and instruction packs in the agent environment,
not necessarily a single community-standard `specs/001-feature` layout.

---

### 9. Spec Kitty (community fork line)

- **Context:** Community tooling often compared as a **Spec Kit–family** variant
  with extra orchestration (e.g. git worktree–oriented workflows in comparison
  writeups)

**Philosophy**

Same core as Spec Kit (constitution + phased feature specs), with extra
**isolation/orchestration** for parallel agent work.

**How it structures a project**

Expect Spec Kit–like `specs/<feature>/` trees plus fork-specific worktree /
parallel-run conventions. Treat as “Spec Kit + operational extras,” not a
separate SDD theory.

---

### 10. Superpowers / skill-based SDD (not a single product)

- **In this vault:** `spec-driven-development`, `writing-plans`, `brainstorming`,
  `executing-plans`, related gstack / cavekit skills

**Philosophy**

**Skills as process:** no mandatory global CLI. The agent loads a skill, writes
`SPEC.md` (or similar), breaks down tasks, implements with TDD. Maximum
portability across harnesses; less product UI/dashboard; quality depends on
skill discipline and human gates.

**How it structures a project (this repo’s common path)**

```text
SPEC.md                 # or docs/SPEC.md / spec/
tasks/
  plan.md
  todo.md
# then code + tests + commits via /build
```

Closest “default” for **dot-agents** today.

---

### 11. Adjacent / enterprise mentions (shorter)

| Name | Notes |
| --- | --- |
| **Augment Cosmos** | Commercial org-scale orchestration + shared memory; specs as operational infrastructure |
| **Cursor rules / plans** | Not full SDD product; project rules + plan mode are lightweight cousins |
| **AWS AI-DLC / specs.md-style** | Formal multi-phase AI development lifecycle (elaboration → construction); heavier methodology |
| **cc-sdd / various “Intent” tools** | Smaller or emerging packages that generate SPEC/ARCHITECTURE/TASKS-style trees |

These matter when comparing *ecosystems*, but the open, repo-native mainstream
core remains **Spec Kit** and **OpenSpec**, with **Kiro / BMAD / GSD / Tessl**
as the next tier people actually name.

---

## Side-by-side (quick)

| Tool | Best mental model | Spec shape | Ceremony | Open / portable |
| --- | --- | --- | --- | --- |
| **OpenSpec** | Delta change → archive into living truth | `openspec/specs` + `changes/*` | Low–medium | Yes (npm) |
| **Spec Kit** | Constitution → feature package → implement | `.specify/` + `specs/00x-name/` | High | Yes (Python) |
| **Kiro** | IDE story loop | requirements / design / tasks | Medium | Product |
| **BMAD** | Multi-persona agile | PRD + docs + role flows | High | Open method |
| **GSD** | Execute hard with context control | plan/tasks harness | Medium | Open system |
| **Tessl** | Spec as source | platform specs | Medium–high | Product |
| **Taskmaster** | Don’t lose the task graph | task store + MCP | Medium | Tooling |
| **Local skills** | Skill-gated SPEC → plan → build | `SPEC.md` + `tasks/` | Low–medium | Already here |

---

## How this maps to *this* repo

| Need | Prefer |
| --- | --- |
| Default personal workflow | Existing `/spec` → `/plan` → `/build` skills |
| Brownfield living domain truth | Study **OpenSpec** (deltas + archive) |
| Greenfield + governance + heavy docs | Study **Spec Kit** (constitution + feature dirs) |
| Multi-role product planning | Study **BMAD** |
| Long autonomous runs | Study **GSD** / Taskmaster-style task memory |
| Spec replaces code as primary artifact | Study **Tessl** |

**Recommendation for tinkering here:** keep products optional and project-local.
Use `spec/` in **dot-agents** for notes, templates, and small harness glue — not
as a forced install of Spec Kit or OpenSpec into every machine profile.

---

## Future work (this folder)

Possible next steps (none required yet):

- [ ] Decision note: when to use local `/spec` vs OpenSpec vs Spec Kit
- [ ] Minimal templates (`SPEC.md`, domain living-spec stub, change delta stub)
- [ ] Optional scripts that validate “a project has a front-door spec”
- [ ] Wire examples into `prompts/` or skills without duplicating gstack/cavekit

---

## Sources / further reading

- [OpenSpec README](https://github.com/Fission-AI/OpenSpec)
- [GitHub Spec Kit](https://github.com/github/spec-kit) · [GitHub Blog: Spec-driven development with AI](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [Martin Fowler Exploring GenAI: Kiro, Spec-kit, Tessl](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- [Addy Osmani: How to write a good spec for AI agents](https://addyosmani.com/blog/good-spec/)
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)
- [GSD / get-shit-done](https://github.com/gsd-build/get-shit-done)
- [Tessl on SDD](https://tessl.io/blog/spec-driven-development-10-things-you-need-to-know-about-specs/)
- [Kiro](https://kiro.dev/)

Catalog last refreshed: 2026-07-11. These tools move quickly; re-check upstream
docs before adopting anything as a permanent harness dependency.
