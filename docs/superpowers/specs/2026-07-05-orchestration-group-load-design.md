# Design: Load Saved Orchestrations into an OrchestrationGroup

## Problem

`AbOrchestrationGroupBuilder` currently offers `orchestrationBy:` and
`orchestrationGroupBy:` to build fresh `AbTopicOrchestration` /
`AbOrchestrationGroup` instances for use as `seq:`/`para:` items. There is no
way to reuse a previously *saved* orchestration or group (via
`AbBaseOrchestration>>saveTo:`) as an item in a new group.

`AbBaseOrchestration class>>loadFrom:` already exists, but it is designed for
`resume`: it deserializes the object as-is, including any `stepResult`,
`previousResult`, and (critically) the `AbTopicBuilder`'s cached `AbTopic`
from the prior run. Dropping such an object straight into a new group and
calling `run` would reuse that stale `AbTopic` (already completed, stale
session) instead of creating a fresh one — the new run would misbehave.

## Goals

- Add `orchestrationLoadFrom: aFileReference` and
  `orchestrationGroupLoadFrom: aFileReference` to `AbOrchestrationGroupBuilder`,
  mirroring the shape of `orchestrationBy:` / `orchestrationGroupBy:`: they
  return the ready-to-use instance; the caller places it into `seq:`/`para:`
  themselves (optionally chaining further configuration, e.g.
  `sharedDirectoryPath:`).
- Guarantee the returned instance runs cleanly from scratch, as if newly
  built, regardless of what state was captured at save time.
- Leave `AbBaseOrchestration class>>loadFrom:` and `resume` untouched — they
  remain the path for pure resume-from-saved-state.

## Non-goals

- No customization block parameter (e.g. `orchestrationLoadFrom:customizing:`)
  — not needed now per user confirmation. Can be added later if needed.
- No change to `save`/`saveTo:`/`loadFrom:` semantics.

## Design

### `resetForRerun`, recursive through the whole tree

A new method, `resetForRerun`, clears all run-produced state so the object
behaves as if freshly built:

- `AbBaseOrchestration>>resetForRerun`
  Clears `previousResult`; forwards `resetForRerun` to each step in `steps`.

- `AbOrchestrationGroupStep>>resetForRerun` (base for the group-level
  sequential/parallel steps)
  Clears `stepResult` and `previousStepResult`; forwards `resetForRerun` to
  each item in `items` (an `AbTopicOrchestration` or `AbOrchestrationGroup` —
  recursion continues polymorphically via `AbBaseOrchestration>>resetForRerun`).

- `AbOrchestrationStep>>resetForRerun` (base for the topic-level
  sequential/parallel steps)
  Clears `stepResult` and `previousStepResult`; forwards `resetForRerun` to
  each `AbTopicBuilder` in `topicBuilders`.

- `AbTopicBuilder>>resetForRerun`
  Clears the cached `topic` instance variable (sets it to `nil`), so the next
  `prepareWith:for:` call creates a fresh `AbTopic` via `createTopic`.

This walks the entire object graph a saved orchestration/group can contain,
so nested groups (via `orchestrationGroupBy:`) are reset too.

### Builder methods

On `AbOrchestrationGroupBuilder`:

```smalltalk
orchestrationLoadFrom: aFileReference
    ^ (AbTopicOrchestration loadFrom: aFileReference)
        resetForRerun;
        yourself

orchestrationGroupLoadFrom: aFileReference
    ^ (AbOrchestrationGroup loadFrom: aFileReference)
        resetForRerun;
        yourself
```

Usage (as sketched by the user):

```smalltalk
groupBuilder para: {
    (groupBuilder orchestrationLoadFrom: aFileReference) sharedDirectoryPath: '...'.
    groupBuilder orchestrationBy: [ :builder | ... ]
}.
```

## Testing

Following TDD, tests will be added to:

- `AbTopicOrchestrationTest` / a new step-level test: `resetForRerun` clears
  `stepResult`/`previousStepResult` on a step and discards a topic builder's
  cached `AbTopic` (verified by identity: the topic returned by `topic`
  differs before/after reset).
- `AbOrchestrationGroupTest`: `resetForRerun` clears `stepResult` on a group
  step and recurses into nested items (using the existing
  `AbMockOrchestrationForGroup` where useful, plus real
  `AbTopicOrchestration`/`AbOrchestrationGroup` instances for the recursive
  case).
- `AbOrchestrationGroupBuilder` tests: `orchestrationLoadFrom:` /
  `orchestrationGroupLoadFrom:` load a previously `saveTo:`-written fixture
  file (with pre-set `stepResult` to simulate a completed run) and assert the
  returned instance has `stepResult`/`previousResult` cleared, and that its
  topic builders' cached topics are gone.
