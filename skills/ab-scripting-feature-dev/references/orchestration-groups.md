> Bundled snapshot for the `scripting-feature-dev` skill. If the current repository has its own `docs/orchestration-groups.md`, prefer that — it may be newer than this copy. Canonical source: https://github.com/mumez/pharo-agentic-browser/blob/main/docs/orchestration-groups.md

# Orchestration Groups: Coordinating Multiple Orchestrations

An `AbTopicOrchestration` (built via `scriptBy:` / `runBy:`, see [Scripting API](scripting.md)) coordinates topics within a single agent workflow. An **Orchestration Group** (`AbOrchestrationGroup`) is one level up: it coordinates multiple whole orchestrations — running them in parallel or in sequence, and even nesting groups inside groups.

This is the tool for patterns like:

- **Arena** — run the same task with different agents/models in parallel, then have a final step pick the best result
- **Fan-out research** — run several independent orchestrations concurrently and merge their outputs
- **Pipelines of pipelines** — run one orchestration, feed its result into the next, where each stage is itself a multi-topic workflow

## Entry Points

| Message | Description |
|---------|-------------|
| `AgenticBrowser groupScriptBy: aBlock` | Build an orchestration group without running it |
| `AgenticBrowser groupRunBy: aBlock` | Build and run; blocks until done |

The block receives an `AbOrchestrationGroupBuilder`.

## Group Builder DSL

| Message | Description |
|---------|-------------|
| `para: aCollection` | Add a node that runs its items (orchestrations or nested groups) concurrently |
| `seq: aCollection` | Add a node that runs its items one after another |
| `orchestrationBy: aBlock` | Create an `AbTopicOrchestration` (same builder as `scriptBy:`); use as an item inside `para:` / `seq:` |
| `orchestrationGroupBy: aBlock` | Create a nested `AbOrchestrationGroup`; use as an item inside `para:` / `seq:` |
| `orchestrationLoadFrom: aFileReference` | Load a previously saved `AbTopicOrchestration` (Fuel) and reset it for a fresh run; use as an item inside `para:` / `seq:` |
| `orchestrationGroupLoadFrom: aFileReference` | Load a previously saved `AbOrchestrationGroup` (Fuel) and reset it for a fresh run; use as an item inside `para:` / `seq:` |
| `singleTopicBy: topicBlock agentBy: agentBlock` | Shortcut: build a one-topic orchestration and add it directly as a sequential group step |
| `sharedDirectoryPath: aString` | Set a common working directory propagated to every item in the group at run time |

`para:` and `seq:` each add one step to the group. A group runs its steps in the order they were added, just like an orchestration runs its topic steps in order.

## Result Flow

Results chain between group steps the same way they chain between topics inside an orchestration:

- A `seq:` group step passes its predecessor's result into each item's `previousResult` before running it, and the last item's result becomes the step's result.
- A `para:` group step runs all its items concurrently, waits for all to finish, then combines their results into one string formatted as `=== item name ===\n<result>` blocks (mirroring topic-level `para:`).
- When an item is itself an `AbTopicOrchestration`, an injected `previousResult` flows into that orchestration's first topic's prompt under the `=== Previous Topic Result ===` header — exactly as it would for a plain, non-grouped orchestration.
- When an item is a nested `AbOrchestrationGroup`, the same injection applies recursively.

This means a final `singleTopicBy:agentBy:` step placed after a `para:` step automatically receives the combined results of every parallel branch in its prompt.

## Loading Saved Orchestrations

`orchestrationLoadFrom:` and `orchestrationGroupLoadFrom:` load a previously saved `AbTopicOrchestration` or `AbOrchestrationGroup` (see [Scripting API: Save and load](scripting.md#save-and-load)) and add it as an item inside `para:` / `seq:`, so a saved workflow can be reused as a building block in a new group without rebuilding it from scratch.

Each call resets the loaded orchestration for a fresh run: any `stepResult`s recorded from a previous run are cleared, and cached topics are dropped, so it runs from its first step rather than resuming or replaying stale results — even if the saved file was written after a completed (or partially completed) run.

```smalltalk
AgenticBrowser groupRunBy: [ :groupBuilder |
    groupBuilder seq: {
        groupBuilder orchestrationLoadFrom: '/path/to/research.fuel' asFileReference.
        groupBuilder orchestrationGroupLoadFrom: '/path/to/nested-group.fuel' asFileReference.
        groupBuilder singleTopicBy: [ :t | t prompt: 'Summarize the results above.' ] agentBy: [ :a | a claude ]
    }
].
```

To instead continue a saved orchestration or group from where it left off (preserving completed step results), load it standalone via `AbTopicOrchestration loadFrom:` / `AbOrchestrationGroup loadFrom:` and call `resume` directly, rather than going through the group builder's `...LoadFrom:` methods.

## Example: Arena Pattern

Run two candidate implementations with different agents in parallel, then have a third agent pick the winner and open a pull request:

```smalltalk
AgenticBrowser groupRunBy: [ :groupBuilder |
    groupBuilder para: {
        groupBuilder orchestrationBy: [ :builder |
            builder seq: {
                builder topicBy: [ :t | t prompt: 'Create a detailed plan for feature XXX.' ].
                builder topicBy: [ :t |
                    t prompt: 'Implement feature XXX according to the plan above.'.
                    t goal: 'all tests pass' ]
            } agentBy: [ :a | a claude; planMode ] ].
        groupBuilder orchestrationBy: [ :builder |
            builder seq: {
                builder topicBy: [ :t | t prompt: 'Create a detailed plan for feature XXX.' ].
                builder topicBy: [ :t |
                    t prompt: 'Implement feature XXX according to the plan above.'.
                    t goal: 'all tests pass' ]
            } agentBy: [ :a | a codex ] ]
    }.
    groupBuilder singleTopicBy: [ :t |
        t prompt: 'Select the best implementation among the candidates above and create a pull request for feature XXX.' ]
    agentBy: [ :a | a kilo ]
].
```

The two `orchestrationBy:` branches run concurrently, each as its own plan → implement pipeline with a different agent. Their combined results are then injected into the final `singleTopicBy:` step's prompt.

## Example: Nested Groups

`orchestrationGroupBy:` lets a group be an item inside another group's `para:` / `seq:`, so whole parallel-or-sequential subtrees can be composed:

```smalltalk
AgenticBrowser groupRunBy: [ :groupBuilder |
    groupBuilder para: {
        groupBuilder orchestrationGroupBy: [ :innerBuilder |
            innerBuilder seq: {
                innerBuilder orchestrationBy: [ :b |
                    b seq: { b topicBy: [ :t | t prompt: 'Draft approach A, step 1.' ] }
                    agentBy: [ :a | a claude ] ].
                innerBuilder orchestrationBy: [ :b |
                    b seq: { b topicBy: [ :t | t prompt: 'Draft approach A, step 2.' ] }
                    agentBy: [ :a | a claude ] ]
            } ].
        groupBuilder orchestrationBy: [ :b |
            b seq: { b topicBy: [ :t | t prompt: 'Draft approach B in one shot.' ] }
            agentBy: [ :a | a codex ] ]
    }
].
```

Here one parallel branch is itself a two-stage sequential group, running alongside a single orchestration in the outer `para:`.

## Shared Working Directory

By default, each orchestration and each topic gets its own working directory. Call `sharedDirectoryPath:` on the group builder to give every item in the group (including nested groups) the same working directory — useful when parallel branches need to read/write files the other branches (or the final step) can see:

```smalltalk
AgenticBrowser groupRunBy: [ :groupBuilder |
    groupBuilder sharedDirectoryPath: '/tmp/arena-feature-xxx'.
    groupBuilder para: { ... }.
].
```

## Timeout

Each item inside a `para:` group step waits up to `orchestrationGroupItemWaitTimeoutSeconds` (default: 900 s). Adjust via settings, same as `orchestrationStepWaitTimeoutSeconds` for topic-level steps (see [Scripting API: Timeout](scripting.md#timeout)).

## Inspecting a Group

`AbOrchestrationGroup` shares `AbBaseOrchestration` with `AbTopicOrchestration`, so the same inspection API applies:

```smalltalk
| groupScript |
groupScript := AgenticBrowser groupScriptBy: [ :groupBuilder | ... ].
groupScript forkRunThen: [ :orc |
    orc explore.  "opens inspector with group state"
    orc result.   "returns the final step's combined/chained result string" ].
```

`forkRunThen:` runs the group in a background process and passes it to the block once finished, without blocking the caller (see [Scripting API: Run in the background](scripting.md#run-in-the-background)).
