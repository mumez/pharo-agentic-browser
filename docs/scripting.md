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

### Timeout

Each step waits up to `orchestrationStepWaitTimeoutSeconds` (default: 900 s) per topic. Adjust globally or per orchestration:

```smalltalk
script settings orchestrationStepWaitTimeoutSeconds: 1800.
```

## Package Structure

| Package | Contents |
|---------|----------|
| `AgenticBrowser-Scripting` | `AbTopicOrchestration`, `AbTopicOrchestrationBuilder`, `AbTopicBuilder`, `AbCodingAgentBuilder`, `AbOrchestrationStep`, `AbSequentialStep`, `AbParallelStep` |
| `AgenticBrowser-Scripting-Tests` | SUnit tests for the Scripting package |
