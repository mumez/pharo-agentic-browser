> Bundled snapshot for the `scripting-feature-dev` skill. If the current repository has its own `docs/scripting.md`, prefer that — it may be newer than this copy. Canonical source: https://github.com/mumez/pharo-agentic-browser/blob/main/docs/scripting.md

# Scripting API

The Scripting package adds a DSL for creating and coordinating multiple AI agent topics programmatically — no UI required.

## Concept

The Spec UI and Web UI let you work with agents interactively. The Scripting API is a third interface: a headless, code-driven way to compose multi-agent workflows. You write a small Smalltalk script, and AgenticBrowser runs the agents, routes results between them, and blocks until everything completes.

This makes it practical to:

- **Automate multi-step workflows** — plan, implement, test, and review in a single script
- **Coordinate agents in parallel** — run independent subtasks concurrently, then collect results
- **Let AI agents author scripts dynamically** — the DSL is simple enough that a coding agent can generate and run orchestration code via `st-eval` during its own session

## Installation

Load the Scripting package alongside the core package:

```smalltalk
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'github://mumez/pharo-agentic-browser:main/src';
    load: 'Scripting'.
```

To also load the Scripting test suite:

```smalltalk
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'github://mumez/pharo-agentic-browser:main/src';
    load: 'Scripting-Tests'.
```

## Quick Start

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder seq: {
        builder topicBy: [ :t | t title: 'Summarize Pharo'. t prompt: 'Write a one-sentence summary of Pharo.' ]
    } agentBy: [ :a | a claude ] ].
```

`runBy:` builds and immediately runs the orchestration. The call blocks until all topics complete.

## DSL Reference

### Entry Points

| Message | Description |
|---------|-------------|
| `AgenticBrowser scriptBy: aBlock` | Build an orchestration without running it |
| `AgenticBrowser runBy: aBlock` | Build and run; blocks until done |

### Orchestration Builder

Inside the block passed to `scriptBy:` / `runBy:`, the builder argument responds to:

| Message | Description |
|---------|-------------|
| `seq: topics agentBy: agentBlock` | Run topics one after another; result flows forward |
| `para: topics agentBy: agentBlock` | Run topics concurrently; wait for all before next step |
| `topicBy: aBlock` | Create a topic builder (used inside `seq:` / `para:` arrays) |
| `sharedDirectoryPath: aString` | Set the working directory each topic works in |

#### `sharedDirectoryPath:`

Sets the working directory each topic in the orchestration operates in. If not specified, a directory is auto-created under `<agenticBrowserRoot>`.

Set this when you want the agents to work against an existing development repository rather than a fresh directory — pointing agents at a known repository also helps them scope their context to the relevant codebase:

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder sharedDirectoryPath: '/path/to/existing/repo'.
    builder seq: {
        builder topicBy: [ :t | t prompt: 'Fix the failing test in lib/foo.js.' ]
    } agentBy: [ :a | a claude ] ].
```

### Topic Builder

Inside `topicBy:`, the block argument responds to:

| Message | Description |
|---------|-------------|
| `title: aString` | Topic display name and default prompt |
| `prompt: aString` | Initial message sent to the agent |
| `goal: aString` | Completion condition; topic runs until `goalAchieved` |

### Agent Builder

Inside `agentBy:`, the block argument responds to:

| Shortcut | Agent |
|---------|-------------|
| `claude` | Claude Code (`claude-agent-acp`) |
| `codex` | Codex (`codex-acp`) |
| `gemini` | Gemini CLI |
| `opencode` | OpenCode |
| `copilot` | GitHub Copilot CLI |
| `cursorAgent` | Cursor CLI |
| `kilo` | Kilo Code |
| `kiro` | Kiro CLI |

Additional configuration:

| Message | Description |
|---------|-------------|
| `planMode` | Start the agent in plan mode (where supported) |
| `model: aString` | Override the model (e.g. `'claude-opus-4-5'`) |

## Result Flow

Results pass automatically between steps:

- In `seq:`, each topic's result is injected into the next topic's prompt under an `=== Previous Topic Result ===` header.
- In `para:`, all topic results are combined and injected into the first topic of the following step.
- A topic's result is its `goal result` file content if a goal was set and achieved; otherwise it is the last AI message text.

## Examples

### Single topic

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder seq: {
        builder topicBy: [ :t |
            t title: 'List Pharo features'.
            t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ]
    } agentBy: [ :a | a claude ] ].
```

### Sequential topics (result flows forward)

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder seq: {
        builder topicBy: [ :t |
            t title: 'List Pharo features'.
            t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ].
        builder topicBy: [ :t |
            t title: 'Summarize Pharo features'.
            t prompt: 'Summarize the feature list from the previous step in one sentence. Reply with only the summary.' ]
    } agentBy: [ :a | a claude ] ].
```

### Parallel topics

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder para: {
        builder topicBy: [ :t |
            t title: 'List Pharo features'.
            t prompt: 'List 3 Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
        builder topicBy: [ :t |
            t title: 'List Pharo tools'.
            t prompt: 'List 3 Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
    } agentBy: [ :a | a claude ] ].
```

### Multiple steps: parallel research → sequential synthesis

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder para: {
        builder topicBy: [ :t |
            t title: 'Research Pharo language'.
            t prompt: 'List 3 key Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
        builder topicBy: [ :t |
            t title: 'Research Pharo tools'.
            t prompt: 'List 3 key Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
    } agentBy: [ :a | a claude ].
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Write Pharo overview'.
            t prompt: 'Write a short overview paragraph of Pharo Smalltalk based on the research results above.' ]
    } agentBy: [ :a | a claude ] ].
```

### Goal-driven topic

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder seq: {
        builder topicBy: [ :t |
            t title: 'Write Pharo summary'.
            t prompt: 'Write a one-sentence summary of what Pharo Smalltalk is.'.
            t goal: 'summary written to goal file' ]
    } agentBy: [ :a | a claude ] ].
```

When a goal is set, the topic runs until the agent writes a `result-<topicId>.md` file in the working directory, at which point the topic transitions to `#goalAchieved`.

### Real-world multi-agent workflow

See [To-do List App: Multi-Agent Orchestration Example](to-do-list-orchestration-script.md) for a complete, runnable script that builds a Spec2 To-do list app from scratch across seven phases — setup, parallel research, design, TDD implementation, UI testing, review, and documentation — mixing agents and models to match task weight.

A minimal version showing the same shape (parallel research → sequential synthesis → goal-driven implementation):

```smalltalk
AgenticBrowser runBy: [ :builder |
    builder para: {
        builder topicBy: [ :t | t prompt: 'Research component A and summarize its API.' ].
        builder topicBy: [ :t | t prompt: 'Research component B and summarize its API.' ]
    } agentBy: [ :a | a claude model: 'haiku' ].
    builder seq: {
        builder topicBy: [ :t | t prompt: 'Write an implementation plan based on the research above.' ].
        builder topicBy: [ :t |
            t prompt: 'Implement feature XXX following the plan above.'.
            t goal: 'all tests pass' ]
    } agentBy: [ :a | a codex ].
    builder seq: {
        builder topicBy: [ :t | t prompt: 'Review the implementation of feature XXX and write a README.' ]
    } agentBy: [ :a | a claude ] ].
```

### Coordinating multiple orchestrations

Everything above coordinates topics *within* one orchestration. To run several whole orchestrations together — in parallel or in sequence, including nesting groups inside groups, e.g. to run the same task with different agents and pick the best result — see [Orchestration Groups](orchestration-groups.md).

## Advanced Usage

### Inspect results after a run

```smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder |
    builder seq: {
        builder topicBy: [ :t | t title: 'Research'. t prompt: 'What is Pharo?' ]
    } agentBy: [ :a | a claude ] ].
script run.
script explore.  "opens inspector with orchestration state"
script result.   "returns the final step result string"
```

### Keep topics visible after run

By default, topics are removed from `AbTopicManager` when the orchestration finishes. To keep them for inspection:

```smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder | ... ].
script settings lingerOrchestrationTopicsAfterRun: true.
script run.
```

### Run in the background

For long-running orchestrations, use `forkRun` or `forkRunThen:` to run in a separate process without blocking the caller. `terminate` interrupts a running orchestration.

```smalltalk
| script |
script := AgenticBrowser scriptBy: [ :builder | ... ].
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ].
"... later, if needed:"
script terminate.
```

`forkRun` is equivalent to `forkRunThen: [ :orc | ]`. `isRunning` reports whether the orchestration's forked process is still alive.

### Look up a running orchestration later

`register` adds the orchestration to `AbOrchestrationManager default`, returning its id. Use the id later — e.g. from another topic or agent session — to retrieve the same instance with `orchestrationAt:`:

```smalltalk
| script id |
script := AgenticBrowser scriptBy: [ :builder | ... ].
id := script register.
script forkRun.

"... later, possibly from a different context:"
(AbOrchestrationManager default orchestrationAt: id) result.
```

Registration is not automatic and orchestrations are not removed automatically after they finish. Call `unregister` when you're done with a specific orchestration, or `AbOrchestrationManager default release` to clear all registered orchestrations at once (this skips any still running).

### Timeout

Each step waits up to `orchestrationStepWaitTimeoutSeconds` (default: 900 s) per topic. Adjust globally or per orchestration:

```smalltalk
script settings orchestrationStepWaitTimeoutSeconds: 1800.
```

If a step times out and the orchestration stops partway through, call `resume` to continue from the first incomplete step, reusing the results already recorded for completed steps:

```smalltalk
script resume.
```

#### Handling timeouts instead of raising the debugger

By default, a step timeout signals `AbOrchestrationStepTimeout`, which raises the debugger if unhandled. You can install a handler instead, at the orchestration level or per step.

**Orchestration-level**, via `runOnTimeout:` (foreground) or `forkRunThen:onTimeout:` (background). Both invoke the handler block with `(timeoutStep, exception)` instead of raising the debugger:

```smalltalk
script runOnTimeout: [ :timeoutStep :ex |
    Transcript crShow: 'Timed out: ' , timeoutStep printString ].
```

```smalltalk
script forkRunThen: [ :orc | Transcript crShow: 'Done: ' , orc result ]
    onTimeout: [ :timeoutStep :ex | Transcript crShow: 'Timed out: ' , timeoutStep printString ].
```

**Per step**, via `onTimeout:` on an individual step (get it from `script steps`). This takes precedence over an orchestration-level handler for that step:

```smalltalk
(script steps first) onTimeout: [ :aStep :ex |
    aStep waitTimeoutSeconds: 1800.
    aStep retry ].
```

`retry` re-runs the step from scratch, so it's typically used together with `waitTimeoutSeconds:` to extend the timeout before retrying. `waitTimeoutSeconds:` updates the step's own `settings` copy (seeded from the orchestration's settings on first use), so it only affects that step — other steps and the orchestration's shared settings are unaffected.

### Save and load

`save` / `saveTo:` and the class-side `loadFrom:` persist an orchestration via Fuel serialization. This works both before and after a run:

- Before running, `save` persists the built configuration (steps, settings, agents) so it can be reconstructed later without re-running the builder block.
- After running (or after a partial run that timed out), `save` also persists each step's recorded `stepResult`, so a loaded copy can be inspected with `result`/`explore`, or continued with `resume`.

```smalltalk
| script loaded |
script := AgenticBrowser scriptBy: [ :builder | ... ].
script save.                                  "-> <sharedDirectoryPath>/<shortReferenceName>.fuel"
"or choose the destination explicitly:"
script saveTo: '/path/to/my-script.fuel' asFileReference.

script run.
script save.                                  "now includes recorded step results"

loaded := AbTopicOrchestration loadFrom: '/path/to/my-script.fuel'.
loaded result.                                 "results from the saved run"
loaded resume.                                 "continue if the saved run stopped early"
```

`loadFrom:` is defined per concrete orchestration class (`AbTopicOrchestration`, `AbOrchestrationGroup`) and errors if the deserialized object isn't an instance of that class.

## Package Structure

| Package | Contents |
|---------|----------|
| `AgenticBrowser-Scripting` | `AbTopicOrchestration`, `AbTopicOrchestrationBuilder`, `AbTopicBuilder`, `AbCodingAgentBuilder`, `AbOrchestrationStep`, `AbSequentialStep`, `AbParallelStep` |
| `AgenticBrowser-Scripting-Tests` | SUnit tests for the Scripting package |
