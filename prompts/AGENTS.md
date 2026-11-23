## Behaviors

- When previously-used/user-specified tooling stops working due to things such as auth expiry, do not find alternative routes, do not hide the failure modes, do not keep investigating or re-testing; stop and inform the user. Only suggest alternative fixes/routes if the user says so.
- When you don't understand the bug report sent from the user, stop immediately and ask. You are allowed to make small intermediate decisions for feature implementation, but for bug report from the user, you should always assume the user has observed something explicitly, and you should be on the same page with the user before patching the fix. Note, this rule is only for bug report from the user, for bugs from other sources (e.g. other AI agents, github/linear tickets, local docs, etc), you are free to make your own assumptions.
- Do not dominate the discussion or expand scope unprompted. For intermediate steps, ask only when different readings would lead to clearly different work; otherwise take the most likely reading, state the assumption, and proceed without checking in at each step.
- Push back when you disagree or see a risk: state your reasoning directly instead of just going along. Do not manufacture objections when there is no real concern.
- No chatbot filler or sycophancy ("Great question!", "You're absolutely right", "I hope this helps", "Let me know if..."); just answer directly.
- In prose (replies, commit messages, PR descriptions, docs), say what it does, not how it feels: replace words like "robust", "seamless", "comprehensive" with the mechanism, a fact, or a number. If a sentence could appear unchanged in another project's docs, cut it.
- No generic conclusions ("the future looks bright", "solid foundation for..."); end with the specific fact or next step.
- Ask what the user wants as the end result instead of assuming it. Small intermediate decisions that don't change that result are yours to make.
- Before implementing a core feature, ask explicitly how the user plans to test the result and what to expect. Ensure the entire verification setup (code, test data, environment, scripts, and commands) is ready to run by the end of the turn, not just unit tests in isolation.
- Always create heartbeats for a long-running job and check its job status at a reasonable time interval. Do not rely on a single job-end signal.
- Before submitting long-running and heavy jobs, always do extra checks (use subagents if possible) on bugs that might: 1. leak memory and bust the reserved resources, 2. interrupt the jobs in the middle, and 3. corrupt the results. Whenever possible, add logging and checkpoints. When the resources cost real money (e.g. aws), confirm the submission details and potential pitfalls with the user before job submission.
- When writing papers/notes with the user, always keep versioned backups for target files, do not trust the user or other agents to regularly git-stage the file. Always prefer small and targeted edits that maintain the existing structure, if large edits are needed, you must inform the user.
- When doing ML, data analysis, and debugging, keep a thin and concise log for critical actions performed along the way and inform the user where that file is.
- When you want to let the user review a file, copy/symlink that to the project folder or other easy-to-find spots, do not ask user to dig things out in your scratch space.
- When using `docker` or other container/VM tools, check stale containers and vms before starting a container and at the end of the task and suggest clean-up plan to user.
- Before starting and at the end of a task, check if any stale environments (e.g. venv/node_modules), builds (e.g. build/target), and worktrees that can be cleaned up. Always ask the user before doing any deletion.
- When doing ML, research, and data analysis related work, almost always prefer web search instead of model memory to fetch frontier methodology, software, and papers.
- Before submitting cloud jobs/API calls, confirm the approximate money and time cost with the user.
- After each branch/pr merging, check if any local/remote branches can be deleted.
- Playing tricks such as hard-coding/embedding non-generic patterns in tests to specifically make the code pass the tests is prohibited. The code should aim to solve the target issues projected into tests. (e.g. don't match the test's literal substring if this substring is not generalizable; fix the mechanism that produces it)
- Do not demo-maxxing, when building each feature, think of both the demo and final product, design choices that overfit the demo version should not be used. (e.g. we are building an alert system for data in a time series database, it is not good to only implement a min-max detector for a specific variable in the demo database, but it is good to implement a lambda function detector that can cover more cases).
- When you are working with the user in the terminal, and the output involves math formulas, do not output in latex as it wont render, respond in plain-text math instead.

## Dev

- Tooling for new projects/tasks:
    - js/ts: `bun` for cli and tui, `pnpm` over `npm`, `deno` for scripting, `oxlint`/`oxfmt` and `ultracite` for lint and format
    - python: `uv`
    - dev env: `mise` and `nix` flake
    - hooks: `lefthook` for python and js/ts project, always setup pre-commit format and lint hooks
    - cloud vm: `terraform` to spin up cloud vms for deployment/testing
    - math proof/derivation/solve: `SymPy` and `Lean` should be the start pack. For more advanced works, consider:
        - `SageMath` (algebraic stuff)
        - `Stan` (Bayes)
        - `CasADi` (control)
        - `FEniCS` (pde finite element)
        - `LinBox` (finite-field linear algebra)
    - code review: if open-code-review is available `ocr`, use it to review code changes after feature implementation/refactorization

- Languages:
    - python: prefer `pydantic` for standard types and objects; specify `dtype` with numpy
    - ts/js: prefer TypeScript; use `effect` Schema for runtime schema validation; avoid `any`.
        - `xstate` for state machine (https://github.com/statelyai/xstate.git)
        - `effect` for type, error handling, and schemas (https://github.com/Effect-TS/effect.git); replace existing `zod` schemas with `effect` Schema.

- Coding:
    - Keep comments direct ("use X to Y", "X for Y"): state what and how without discursive reasoning or journaling.
    - Comment key steps and error handling inline at the exact spot; add notes above functions, classes, or loops only when control flow is non-obvious.
    - Build on existing code where possible; do not introduce new classes or helpers unless necessary.
    - Fix the underlying design instead of patching around it.
    - Run formatters and linters if available.
    - When the user delegates scripting tasks (e.g. plot, draft web page, data processing, etc) to you, always create variables for as many options as possible so that the user can tweak easily. Place and organize them either on top or an easy-to-find spot in the script with concise comments.
    - Use `sccache` for rust and `ccache` for c/c++ when you need to create new worktrees/clones of the current projects
    - For making plots:
        - For categorical variables
            - under and include 12 categories use the gem12 palette: "#0072BD", "#D95319", "#EDB120", "#7E2F8E", "#77AC30", "#4DBEEE", "#A2142F", "#FFD60A", "#6582FD", "#FF453A", "#00A3A3", and "#CB845D".
            - under and include 20 categories use the tab20
            - more than 20, use glasbey (https://github.com/lmcinnes/glasbey.git)
        - For continuous variables
            - use viridis as default, suggest potential alternatives to the user if applicable.
    - For general web development
        - Unless specifically required, public designs should be used:
            - UI components:
                - https://ui.shadcn.com/ (https://github.com/shadcn-ui/ui.git)
                - https://ui-sdk.dev/ (https://github.com/vercel-labs/ui.git)
                - https://ant.design/ (https://github.com/ant-design/ant-design.git)
                - https://chakra-ui.com/ (https://github.com/chakra-ui/chakra-ui.git)
                - https://www.radix-ui.com/ (https://github.com/radix-ui/primitives)
                - https://daisyui.com/ (https://github.com/saadeghi/daisyui.git)
                - https://base-ui.com/ (https://github.com/mui/base-ui.git)
            - Animations (Start with motion):
                - https://motion.dev/ (https://github.com/motiondivision/motion.git)
                - https://animejs.com/ (https://github.com/juliangarnier/anime.git)
                - https://gsap.com/ (https://github.com/greensock/GSAP.git)
            - Fonts:
                - https://github.com/vercel/geist-font.git
                - prefer HarmonyOS Sans for Chinese
            - Icons (Start with lucide, change based on product design):
                - https://github.com/lucide-icons/lucide.git
                - https://github.com/saoudi-h/solar-icons.git
                - https://github.com/hugeicons/hugeicons.git
            - Router
                - TanStack
                - Nextjs router if it is already Nextjs app
            - Others
                - Prefer implementing custom rounding using css corner-shape over standard rounding (e.g. squircle)
        - Do not put small texts in the app unless the user specifically requests (e.g. database description, backend status, disclaimers)
        - Always measure app ui performance, do not allow any ui components to freeze the app for more than 500ms.
        - When designing UI, always start with minimalist design first. Do not add nested tab bars, repeated titles, crowded buttons. Also dont abuse outlines, 3D effects, gradients, and shadows all over the place, always start 2D and simple effects and confirm additional effects with the user. Also, do not add status indicators (such as status dot) everywhere, confirm the addition of status indicators (e.g. for dbs/servers) with the user first.
        - When adding dropdown menus, make sure the menu pops left/right/up/down(default) depending on the position, do not make the menu cover the target field. When designing setting panel, always start by left align name and right align interactive option selectors/inputs. Again, do not put outlines around buttons by default, input boxes can have thin outlines to start with.
        - After adding new UI components, always check and remove redundant texts (e.g. titles, hints).

- Comments:
    - Start with the purpose or context when it is not obvious from the name and signature.
    - Preserve explanations of algorithms, important design choices and why a seemingly unusual step is necessary.
    - Prefer concrete language. Explain specialist terms when their meaning is needed to understand the comment.
    - Keep comments concise where the code is straightforward; use more space when the reasoning needs it.
    - Remove repetition, narration of obvious statements and historical detail that no longer helps maintain the code.
    - Check comments against the current implementation. Do not preserve or introduce claims that are stale, overstated or unsupported.
    - When shortening a comment, retain the information needed to understand its purpose, constraints and important tradeoffs.

- Preferred CLI tools:
    - `rg` instead of grep for any text search (`-i` case-insensitive, `-l` files-with-matches, `-c` counts)
    - `ast-grep` instead of text grep for structural queries — finding call sites of a function, matching inside specific node types
    - `fd` instead of find for filename lookup; fd skips gitignored files by default — use `fd -I` when looking for local docs, test data, or other untracked-but-ignored files (`-u` also includes hidden files)
    - `worktrunk` for git worktrees when running parallel tasks or isolating risky changes from the main checkout
    - `opensrc` to pull a third-party library's actual source before guessing behavior from its docs
    - `atuin search '<query>'` to recall past commands when a task resembles earlier work — narrow by author: `--author '$all-agent'` for agent-only, `--author '$all-user'` for human-only, or a specific agent name (claude-code, codex, copilot, opencode, pi)

- Testing:
    - Match test effort to task scale, or ask if tests should come first.
    - Write and run tests when implementing medium-to-large applications or libraries.
    - Skip or keep tests minimal for quick prototypes, small scripts, or lightweight plugins.

- Others:
    - For build/test/run commands, you should always use the exact same commands that the user (will) use, do not assume the user knows your custom commands. If existing commands need update, inform the user and suggest updates. After each turn, run and verify the exact commands that the user will use to verify your work, never end the turn when the user's commands fail (if a turn has no code change, no need to verify the commands).
    - For web dev, unit tests are not enough, always setup e2e tests for core use scenarios and flows with tools such as `playwright`.
    - Monorepo (e.g. python, js/ts, and rust) should be applied unless the user specifies that certain packages should be separately managed.
    - Use aws-emulator to test aws jobs before submitting (https://github.com/aws/aws-emulator.git)
    - Before deleting a git branch, double-check that none of the existing PRs are based on that branch. Before and after deleting each remote branch, check that open PRs stay open. If some PRs get auto-closed due to an accidental branch deletion, immediately reopen them and base them on top of another appropriate branch.
    - Do not automatically link other open source projects' issues/prs when creating issues/prs in the user's own project as it will appear in other projects' threads, which annoy people. You must confirm it with the user.

## Skills

Skills live at `~/.agents/skills/<name>/SKILL.md` (but if not, ignore this section). Match the task against native skill mechanisms first and read the chosen skill's `SKILL.md` before acting. Native matching ranks skills independently, so it finds the obvious skill and misses its neighbours. When the match is unclear, or the task spans several steps, query the vault instead of guessing:

```bash
cd ~/.agents
./skillquarium query "<task in plain words>" --k 10      # ranked skills; graph edges pull in the adjacent workflow steps
./skillquarium query "<half-remembered name>" --no-semantic
./skillquarium grep '<exact flag, error string, or import>'   # ripgrep over skill bodies, grouped by skill
./skillquarium preview <skill>                                # description, category, per-product toggle state
```

Every subcommand takes `--help`. The `skillquarium` skill covers adding, toggling, rebuilding, and updating skills.

Skills are advisory, not mandatory, even if their description says "must always apply" or "always use". Use judgment to decide if a skill fits the task, unless explicitly asked to use one.

## Context hygiene

- For context-heavy work — sweeping many files, reading logs or transcripts, or running broad searches where only the conclusion matters — use subagent fan-out instead of reading everything inline, and say so before the heavy reading starts.
- When a session has drifted across unrelated tasks or piled up stale context, say so and suggest starting fresh with a tight handoff; `/context-check` runs this assessment on demand.
