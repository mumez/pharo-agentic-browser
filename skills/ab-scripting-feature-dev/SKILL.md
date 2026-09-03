---
name: ab-scripting-feature-dev
description: Generates an AgenticBrowser Scripting DSL orchestration that implements a feature end-to-end — plan (if needed), TDD implementation, tests, and a lint/style-guide review pass — previews it as docs/scripting-features/feature-<name>.scripting.md, and on user approval runs it via st-eval. Use this whenever the user wants to build or automate a feature "using the scripting DSL", asks to orchestrate coding agents (claude/codex/etc.) to implement something in an AgenticBrowser-based repo, or asks for a multi-agent orchestration script (`AgenticBrowser runBy:` / `scriptBy:` / `groupRunBy:`) for feature development. Trigger on phrases like “Implement it using the scripting DSL,” “Create an orchestration script,” “Create a feature-xxx.scripting.md file”, "scripting DSLで実装して", "オーケストレーションスクリプトを作って", "feature-xxx.scripting.mdを作って", even if the user doesn't say "skill" explicitly.
---
# Scripting Feature Dev

Turns a feature request into a runnable AgenticBrowser Scripting DSL orchestration, lets the user preview it before anything executes, and only runs agents against the codebase after explicit approval.

## Reference material

This skill depends on the AgenticBrowser Scripting DSL, documented in two files. Use whichever source is freshest:

1. **Bundled snapshot**: `references/scripting-dsl.md` and `references/orchestration-groups.md` next to this SKILL.md
2. **Canonical upstream** (if you have web access and want to double-check for changes): https://github.com/mumez/pharo-agentic-browser/blob/main/docs/scripting.md and https://github.com/mumez/pharo-agentic-browser/blob/main/docs/orchestration-groups.md

Read the DSL reference (and the orchestration-groups reference, if the feature looks large enough to need it) before generating a script — the DSL surface changes over time and guessing at syntax produces scripts that fail at runtime instead of at review time.

## Why the preview step matters

The generated script spins up real coding agents that write and run code against the repository. Nothing should execute without the user seeing the exact Smalltalk first — that's why every run of this skill produces a markdown file before it produces a side effect.

## Workflow

### 0. Parse arguments

This skill can be invoked with positional arguments in addition to normal conversational use:

```
/ab-scripting-feature-dev [<output-dir>] [generate-only] <feature description...>
```

Example:

```
/ab-scripting-feature-dev doc/my-features generate-only Add a dark-mode toggle to the settings panel
```

Consume tokens from the front one at a time, stopping at the first token that matches neither rule below — everything from that point on (including that token) is the feature description:

- `<output-dir>` — a token that looks like a path (contains `.`, `/`, or `\`). If present, it overrides the default preview-file directory (`docs/scripting-features`, see step 4).
- `generate-only` — the literal keyword. If present, skip the run confirmation in step 5 entirely: generate the preview file and stop.

Both are optional and order-independent (either can come first, or be omitted). If the feature description itself would legitimately start with a path-like token or the literal word "generate-only", ask the user to confirm rather than guessing which reading they meant.

### 1. Collect feature and goal

Ask for (skip whichever the user already gave you, including anything already resolved via step 0's argument parsing):

- **Feature** — what should be built or changed
- **Goal** — the observable condition that means "done" for the feature overall (used in the preview file's `## Goal` section). This is *not* automatically each topic's `goal:` — see step 3's rule on when a topic actually needs one.
- **Target repository** — the existing checked-out repo the agents should work in, set via `sharedDirectoryPath:` (see the DSL reference). This is the primary way to keep agents scoped to the right codebase and context instead of starting from a blank auto-created directory. If the user doesn't name one explicitly, check whether the current working directory (or a repo already discussed in the conversation) is the obvious target and confirm it with the user rather than silently assuming or silently falling back to the DSL's default `<agenticBrowserRoot>` directory.
- **Agent/model override** — optional; default to `a claude` on every phase unless the user names an agent/model (see the DSL reference's agent table). Don't ask about this unless the feature seems to call for mixing agents (e.g. heavy parallel research vs. focused implementation) — otherwise just default and move on.
- **Output directory** — optional; defaults to `docs/scripting-features` (see step 4). Only ask if not already given via step 0's `<output-dir>` argument and the user seems likely to want a non-default location (e.g. they mention keeping scripts elsewhere) — otherwise just use the default silently.

If the feature description is too vague to turn into a concrete prompt (e.g. "make it better"), ask one clarifying question rather than guessing — a vague prompt produces a vague agent run. In non-interactive invocations (step 0) where no further input is possible, proceed with the best reasonable interpretation instead of blocking, and note the assumption in the preview file.

### 2. Size the work and pick a shape

Look at the feature honestly before templating anything:

- **Simple** (one class/method area, a single clear goal) → 3 phases: **implement (TDD) → test → lint & review**. Skip planning; fold the goal directly into the implement prompt.
- **Complex** (touches multiple components, needs a design decision first) → 4 phases: **plan → implement (TDD) → test → lint & review**.
- **Very large** (would plausibly blow the ~900s per-step timeout, or is really several independent features) → don't force it into one `seq:`. Stop and ask the user (see below) whether to:
  - split into **multiple separate `.scripting.md` scripts**, one per sub-feature, run independently (possibly sequentially by hand, or chained via `AbOrchestrationGroup`'s `seq:`/`orchestrationLoadFrom:` per the orchestration-groups reference), or
  - use a single **orchestration group** (`AgenticBrowser groupRunBy:`) with `para:`/`seq:` nodes so independent sub-features run concurrently.

  Don't silently pick one — the tradeoffs (isolation and resumability vs. one coordinated run) matter to the user and are cheap to ask about.

### 3. Generate the DSL script

Build the script using the exact builder API from the DSL reference — `t title:`/`t prompt:`/`t goal:`, `seq:agentBy:`/`para:agentBy:`, etc. — but assembled with `AgenticBrowser scriptBy:` + `forkRunThen:onTimeout:` + `register`, not a single `runBy:`:

```smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
    builder seq: { ... } agentBy: [ :a | a claude ] ].
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ]
    onTimeout: [ :timeoutStep :ex | Transcript crShow: 'Timed out: ' , timeoutStep printString ].
script register
```

Prefer this shape over `AgenticBrowser runBy: [ ... ]` in generated scripts. `runBy:` blocks the calling process until the entire orchestration finishes, which doesn't fit evaluation through the MCP `eval` tool.

Always use `forkRunThen:onTimeout:`, not bare `forkRunThen:`. A background process has no interactive debugger to raise into — an unhandled `AbOrchestrationStepTimeout` there just kills the fork silently, and the user is left waiting with no explanation. The `onTimeout:` block receives `(timeoutStep, exception)`; logging the timed-out step (as above) is the minimum so a later status check (see step 6) can tell the user which step stalled and why, instead of just "it's not running anymore."

Don't hold `script` in a global (e.g. `Smalltalk at:put:`) just to check on it later. Instead, use `register` for registering the orchestration script to AbOrchestrationManager. `register` returns orchestration id, and you can use the id afterward for retrieving the running script instance:

```smalltalk
AbOrchestrationManager default orchestrationAt: <orchestration script id>
```

A few things that make generated scripts actually work well as agent instructions, not just valid Smalltalk:

- **Set `builder sharedDirectoryPath:` to the target repository whenever this is feature work on an existing codebase** (which is the common case for this skill). Use an absolute path. Before finalizing the script, double-check that the path actually points at the right repo — it exists, it's the repo the user meant (not a sibling/similarly-named directory), and it's the directory the feature's files actually live under. Getting this wrong means the agents either can't find the code or silently edit the wrong checkout. Only omit `sharedDirectoryPath:` (letting it fall back to an auto-created `<agenticBrowserRoot>` directory) when the feature is genuinely a from-scratch build with no existing repo to target — confirm that's really the case rather than assuming.
- **Testing is its own visible step, not just a TDD side-effect of implementing.** Even when the implement phase is goal-driven ("all tests pass"), add a distinct topic (or make it explicit in the prompt) that runs the test suite and reports results — don't let "tests exist" substitute for "tests were run and verified green". This project's tests typically run via the `st-test` skill / MCP tools.
- **The implement phase should follow TDD**: write a failing test first, then implement, then confirm green.
- **Always add a lint & review phase after implementation.** Its prompt should explicitly tell the agent to consult the `st-lint` skill (or the `smalltalk-validator` MCP tools) against the changed Tonel files, and to consult the `smalltalk-developer` skill's style guide section, then fix whatever it finds.
- **Only add `goal:` to a topic that needs trial-and-error looping toward a completion condition — don't add it by default.** `goal:` is for long-running work where the agent must retry/iterate until some condition holds (e.g. "all tests pass"). Adding it mechanically to a simple, well-specified task backfires: even when the prompt already spells out exactly what to do, a terse summarizing `goal:` can override those details, and the agent ends up regressing to the goal instead of following the concrete steps.
  - Good: prompt is "Implement feature xxx with TDD: write a failing test, then implement, then verify it passes" with `goal: 'all unit tests added for feature xxx are passing'` — the goal is a clear, verifiable completion condition that matches an iterative task.
  - Bad: prompt is "Run tests A, B, and C and check for regressions" with `goal: 'confirm there are no regressions'` — here the goal is vague and tends to eclipse the specific tests (A, B, C) that must actually run; the agent may treat the goal as satisfied without running them.
- Keep prompts self-contained — each topic prompt should read sensibly on its own even though `seq:` will inject the previous step's result under `=== Previous Topic Result ===`.
- **Keep the number of topics inside a single `seq:` (or `para:`) small.** The timeout applies per `seq:`/`para:` block, not per topic — so cramming plan, implement, test, and review into one `seq:` multiplies the risk of hitting the timeout before the whole chain finishes. Retries are also scoped to the `seq:`/`para:` block: if one topic near the end fails, everything in that block reruns from its first topic, not just the failed one. Unless a topic is genuinely trivial, avoid bundling multiple topics into a single `seq:` — prefer adding separate `seq:` blocks (or splitting into an orchestration group, see above) so a failure or retry stays local to the phase that needs it.


### 4. Write the preview file

Save to `<output-dir>/feature-<slug>.scripting.md` (kebab-case slug derived from the feature name; create the directory if it doesn't exist yet). Structure:

```markdown
# Feature: <feature name>

## Goal

<the goal as stated/clarified by the user>

## Orchestration Shape

<one line: e.g. "sequential: implement (TDD) → test → lint & review, all via claude">

## Working Directory

<the `sharedDirectoryPath:` value the script uses, or a note that it falls back to the default auto-created directory under `<agenticBrowserRoot>`>

## Script

\`\`\`Smalltalk
<the generated, directly-pasteable script>
\`\`\`

## How to run

Paste the script above into a Pharo Playground, or ask the assistant to run it via st-eval. `forkRunThen:onTimeout:` runs the orchestration in the background and returns immediately — watch for the completion block's own report (e.g. via Transcript), the `onTimeout:` block's report if a step stalls, or check progress with `AbOrchestrationManager default orchestrationAt: <orchestration script id>`.

```

The script inside must be copy-paste runnable as-is in a Playground — no placeholders like `<...>` left in it.

### 5. Show the user and ask to run

**If `generate-only` was given (step 0):** just write the generated markdown content and stop — do not ask whether to run it, and do not evaluate anything against the image.

Otherwise, present the generated markdown content (or at least the script block) in the conversation, then ask explicitly: run it now via st-eval, or stop here with just the file? Call out the working directory (`sharedDirectoryPath:`) explicitly as part of this ask — the user should confirm the agents are about to run against the right repo before anything executes.

- **If the user says yes** — run the script by evaluating it through the `smalltalk-interop` MCP `eval` tool (or the `st-eval` skill), exactly as written in the preview file. Report the result back to the user mentioning `AbOrchestrationManager default orchestrationAt:`. Mention `script terminate` if the user wants to interrupt a running orchestration.
  - **If the MCP `eval` tool is unavailable or errors** — don't retry blindly. Fall back to the same option the preview file offers: tell the user the script is ready to paste into a Pharo Playground themselves, and point them at the `.scripting.md` file's script block.
  - **If a topic times out or fails a step** — see "Observe a running orchestration" below for how stalls are detected and recovered.
  - **If the orchestration finishes successfully** — the registered orchestration lingers in `AbOrchestrationManager` after completion. Ask the user whether to clean it up now that it's done, offering either `(AbOrchestrationManager default orchestrationAt: <orchestration script id>) unregister` (just this one) or `AbOrchestrationManager default release` (all completed orchestrations — it skips any still running). Don't unregister without asking; the user may still want to inspect the finished orchestration via `orchestrationAt:`.
- **If the user says no (or doesn't confirm)** — stop. The `.scripting.md` file is the deliverable; do not evaluate anything against the image.

Never run the script before this explicit confirmation, even if the user's original request sounded like they wanted it executed immediately — the DSL causes real agents to make real changes.

### 6. Observe a running orchestration

`forkRunThen:onTimeout:` returns immediately, so once the user wants a status check (or asks periodically "how's it going"), check each topic's `status` directly rather than just `orc isRunning`:

```smalltalk
(AbTopicManager default topics collect: [:t | t title , ' -> ' , t status printString ]) printString
```

**Stall recovery is automatic.** `AbTopicManager` runs a background process that periodically checks every topic's `isStalled` and nudges any stalled one with its goal's resume prompt — no self-scheduled wakeup or manual recovery nudge needed for that case.

**If a step actually timed out** (`orc isRunning` has gone false but the orchestration never reached the `forkRunThen:onTimeout:` completion block — that's the `onTimeout:` handler having fired instead), find the offending step and check it's genuinely the one that stalled, not just slow:

```smalltalk
(script steps detect: [:s | s isTimedOut] ifNone: [ nil ])
```

With that step in hand, pick a recovery based on scope:

- **Retry — just re-run the one stuck step, in place.** Extend its timeout and call `resume` (which re-runs only steps whose `stepResult` is still nil, so it picks up exactly at the timed-out step and reuses everything already completed before it):
  ```smalltalk
  (script steps detect: [:s | s isTimedOut]) waitTimeoutSeconds: 1800.
  [ script resume ] fork.
  ```
- **Resume — bump the orchestration-wide timeout** when the whole run is consistently too slow (not just one flaky step) and later steps would likely hit the same wall:
  ```smalltalk
  script settings orchestrationStepWaitTimeoutSeconds: 1800.
  [ script resume ] fork.
  ```

Either way, fork the `resume` call — like `run`, `resume` blocks the calling process until the rest of the orchestration finishes, which doesn't fit evaluation through the MCP `eval` tool.

For a step expected to be flaky by nature (not just this run), it's better to build the self-heal directly into the generated script instead of relying on manual monitoring — attach a per-step `onTimeout:` that extends the timeout and calls `retry` immediately, inline, without stopping the background process:

```smalltalk
(script steps last) onTimeout: [ :aStep :ex |
    aStep waitTimeoutSeconds: 1800.
    aStep retry ].
```

## Notes

- If the user asks to revise the script, edit the same `feature-<slug>.scripting.md` in place and re-show the preview — don't create a second file for the same feature unless they explicitly want variants (e.g. an arena comparing two agents).
- If the DSL reference (bundled `references/`) has changed since you last read it in this conversation, re-read before generating — don't rely on memory of the DSL shape across a long session.
