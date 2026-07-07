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
groupScript run.
groupScript explore.  "opens inspector with group state"
groupScript result.   "returns the final step's combined/chained result string"
```
