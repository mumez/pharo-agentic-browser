# Load Saved Orchestrations into an OrchestrationGroup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let `AbOrchestrationGroupBuilder` load a previously `saveTo:`-persisted `AbTopicOrchestration` or `AbOrchestrationGroup` from disk and reuse it as a fresh, re-runnable item in a new group, via `orchestrationLoadFrom:` / `orchestrationGroupLoadFrom:`.

**Architecture:** Add a recursive `resetForRerun` method across the orchestration object graph (`AbBaseOrchestration`, `AbOrchestrationGroupStep`, `AbOrchestrationStep`, `AbTopicBuilder`) that clears every piece of run-produced state, including `AbTopicBuilder`'s lazily-cached `AbTopic`. Then add two builder methods that call `AbBaseOrchestration class>>loadFrom:` (already exists, Fuel-based) followed by `resetForRerun`, returning the ready-to-use instance — the same shape as the existing `orchestrationBy:`/`orchestrationGroupBy:`.

**Tech Stack:** Pharo Smalltalk, Tonel file format, SUnit, Fuel serialization (`FLSerializer`/`FLMaterializer`, already in use).

## Global Constraints

- Spec: `docs/superpowers/specs/2026-07-05-orchestration-group-load-design.md`
- Follow TDD: write the failing test first for every step that adds behavior.
- When editing `.st` files, consult the `smalltalk-developer` skill (style guide) before writing Tonel syntax; consult `smalltalk-debugger` if a test fails unexpectedly.
- After editing `.st` files, use the `st-import` skill to load them into the running Pharo image, then `st-test` to run the affected test classes. Do not just trust static review — tests must actually run green in the image.
- No new classes or files are created — all changes are new methods on existing classes.
- `AbBaseOrchestration class>>loadFrom:` and `resume` must remain unchanged.

---

### Task 1: `resetForRerun` at the topic-builder / topic-step level

**Files:**
- Modify: `src/AgenticBrowser-Scripting/AbTopicBuilder.class.st`
- Modify: `src/AgenticBrowser-Scripting/AbOrchestrationStep.class.st`
- Test: `src/AgenticBrowser-Scripting-Tests/AbTopicOrchestrationTest.class.st`

**Interfaces:**
- Consumes: existing `AbTopicBuilder>>topic` (lazily creates/caches an `AbTopic`), existing `AbOrchestrationStep` instance variables `stepResult`, `previousStepResult`, `topicBuilders` (all already defined).
- Produces:
  - `AbTopicBuilder>>resetForRerun` — clears the cached `topic` (sets ivar to `nil`); no return value used by callers.
  - `AbOrchestrationStep>>resetForRerun` — clears `stepResult` and `previousStepResult` to `nil`; forwards `resetForRerun` to every builder in `topicBuilders`. Later tasks (Task 2) call this via polymorphism from `AbBaseOrchestration>>resetForRerun`, so the method name and zero-argument signature must match exactly.

- [ ] **Step 1: Write the failing tests**

Add to `AbTopicOrchestrationTest` (category `'tests'`):

```smalltalk
AbTopicOrchestrationTest >> testTopicBuilderResetForRerunDiscardsCachedTopic [
	| builder firstTopic secondTopic |
	builder := AbTopicBuilder new.
	firstTopic := builder topic.
	builder resetForRerun.
	secondTopic := builder topic.
	self deny: firstTopic == secondTopic
]

AbTopicOrchestrationTest >> testOrchestrationStepResetForRerunClearsResultsAndTopicBuilders [
	| step builder firstTopic secondTopic |
	builder := AbTopicBuilder new.
	firstTopic := builder topic.
	step := AbOrchestrationSequentialStep new
		topicBuilders: (OrderedCollection with: builder);
		stepResult: 'old-result';
		previousStepResult: 'old-previous';
		yourself.
	step resetForRerun.
	self assert: step stepResult isNil.
	self assert: step previousStepResult isNil.
	secondTopic := builder topic.
	self deny: firstTopic == secondTopic
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use the `st-import` skill to load the (unchanged-yet) `AgenticBrowser-Scripting-Tests` package, then the `st-test` skill to run `AbTopicOrchestrationTest`. Both new tests must fail with `MessageNotUnderstood: resetForRerun` (or similar), confirming the method does not exist yet.

- [ ] **Step 3: Implement `AbTopicBuilder>>resetForRerun`**

In `src/AgenticBrowser-Scripting/AbTopicBuilder.class.st`, add (category `'actions'`):

```smalltalk
{ #category : 'actions' }
AbTopicBuilder >> resetForRerun [
	topic := nil
]
```

- [ ] **Step 4: Implement `AbOrchestrationStep>>resetForRerun`**

In `src/AgenticBrowser-Scripting/AbOrchestrationStep.class.st`, add (category `'running'`):

```smalltalk
{ #category : 'running' }
AbOrchestrationStep >> resetForRerun [
	stepResult := nil.
	previousStepResult := nil.
	self topicBuilders do: [ :builder | builder resetForRerun ]
]
```

- [ ] **Step 5: Reimport and run tests, verify they pass**

Use `st-import` to load both modified packages, then `st-test` to run `AbTopicOrchestrationTest`. Both new tests must pass. Also run the full `AbTopicOrchestrationTest` suite to confirm no regressions (in particular the `testResume*` tests, which rely on `stepResult` continuing to work as before).

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbTopicBuilder.class.st src/AgenticBrowser-Scripting/AbOrchestrationStep.class.st src/AgenticBrowser-Scripting-Tests/AbTopicOrchestrationTest.class.st
git commit -m "Add resetForRerun to AbTopicBuilder and AbOrchestrationStep"
```

---

### Task 2: `resetForRerun` at the orchestration / group-step level (recursive)

**Files:**
- Modify: `src/AgenticBrowser-Scripting/AbBaseOrchestration.class.st`
- Modify: `src/AgenticBrowser-Scripting/AbOrchestrationGroupStep.class.st`
- Test: `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`

**Interfaces:**
- Consumes: `AbOrchestrationStep>>resetForRerun` and `AbTopicBuilder>>resetForRerun` from Task 1; existing `AbBaseOrchestration` ivars `previousResult`, `steps`; existing `AbOrchestrationGroupStep` ivars `stepResult`, `previousStepResult`, `items`.
- Produces:
  - `AbBaseOrchestration>>resetForRerun` — clears `previousResult`; forwards `resetForRerun` to every step in `steps`. This is the entry point Task 3's builder methods call.
  - `AbOrchestrationGroupStep>>resetForRerun` — clears `stepResult` and `previousStepResult`; forwards `resetForRerun` to every item in `items` (each item is an `AbTopicOrchestration` or `AbOrchestrationGroup`, both `AbBaseOrchestration` subclasses, so this recurses polymorphically through `AbBaseOrchestration>>resetForRerun` — including into nested groups created via `orchestrationGroupBy:`).

- [ ] **Step 1: Write the failing tests**

Add to `AbOrchestrationGroupTest` (category `'tests'`):

```smalltalk
AbOrchestrationGroupTest >> testGroupStepResetForRerunClearsResultsAndItems [
	| step orch |
	orch := AbTopicOrchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	orch previousResult: 'stale-previous'.
	orch steps first stepResult: 'stale-step-result'.
	step := AbOrchestrationGroupSequentialStep new
		items: (OrderedCollection with: orch);
		stepResult: 'stale-group-step-result';
		previousStepResult: 'stale-group-previous-step-result';
		yourself.
	step resetForRerun.
	self assert: step stepResult isNil.
	self assert: step previousStepResult isNil.
	self assert: orch previousResult isNil.
	self assert: orch steps first stepResult isNil
]

AbOrchestrationGroupTest >> testGroupResetForRerunRecursesIntoNestedGroup [
	| innerGroup outerGroup orch |
	orch := AbTopicOrchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	orch steps first stepResult: 'stale-inner-result'.
	innerGroup := AbOrchestrationGroup buildBy: [ :b |
		b seq: (OrderedCollection with: orch) ].
	outerGroup := AbOrchestrationGroup buildBy: [ :b |
		b seq: (OrderedCollection with: innerGroup) ].
	outerGroup previousResult: 'stale-outer-previous'.
	outerGroup resetForRerun.
	self assert: outerGroup previousResult isNil.
	self assert: orch steps first stepResult isNil
]
```

- [ ] **Step 2: Run tests to verify they fail**

`st-import` the `AgenticBrowser-Scripting-Tests` package, then `st-test` on `AbOrchestrationGroupTest`. Both new tests must fail with `MessageNotUnderstood: resetForRerun`.

- [ ] **Step 3: Implement `AbBaseOrchestration>>resetForRerun`**

In `src/AgenticBrowser-Scripting/AbBaseOrchestration.class.st`, add (category `'running'`):

```smalltalk
{ #category : 'running' }
AbBaseOrchestration >> resetForRerun [
	previousResult := nil.
	self steps do: [ :step | step resetForRerun ]
]
```

- [ ] **Step 4: Implement `AbOrchestrationGroupStep>>resetForRerun`**

In `src/AgenticBrowser-Scripting/AbOrchestrationGroupStep.class.st`, add (category `'running'`, a new category on this class — existing categories are `'accessing'`; use `'running'` to match sibling classes like `AbOrchestrationStep`):

```smalltalk
{ #category : 'running' }
AbOrchestrationGroupStep >> resetForRerun [
	stepResult := nil.
	previousStepResult := nil.
	self items do: [ :item | item resetForRerun ]
]
```

- [ ] **Step 5: Reimport and run tests, verify they pass**

`st-import` both modified packages, then `st-test` on `AbOrchestrationGroupTest` and `AbTopicOrchestrationTest` (full suites, to confirm no regressions from Task 1 or Task 2 changes — in particular `AbMockOrchestrationForGroup` does not implement `resetForRerun`, but it is never asked to reset in these tests, so this is fine).

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbBaseOrchestration.class.st src/AgenticBrowser-Scripting/AbOrchestrationGroupStep.class.st src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st
git commit -m "Add resetForRerun to AbBaseOrchestration and AbOrchestrationGroupStep"
```

---

### Task 3: `orchestrationLoadFrom:` / `orchestrationGroupLoadFrom:` on the group builder

**Files:**
- Modify: `src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st`
- Test: `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`

**Interfaces:**
- Consumes: `AbBaseOrchestration class>>loadFrom:` (existing, `src/AgenticBrowser-Scripting/AbBaseOrchestration.class.st:63`), `AbBaseOrchestration>>resetForRerun` (Task 2), `AbBaseOrchestration>>saveTo:` (existing, used only in the test to create a fixture file).
- Produces:
  - `AbOrchestrationGroupBuilder>>orchestrationLoadFrom: aFileReference` — returns a reset, ready-to-use `AbTopicOrchestration`.
  - `AbOrchestrationGroupBuilder>>orchestrationGroupLoadFrom: aFileReference` — returns a reset, ready-to-use `AbOrchestrationGroup`.
  Both mirror `orchestrationBy:`/`orchestrationGroupBy:` (`src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st:56-63`): they do not add the result to the group themselves; the caller places it into `seq:`/`para:`.

- [ ] **Step 1: Write the failing tests**

Add to `AbOrchestrationGroupTest` (category `'tests'`). These write a real Fuel fixture to a temp path, pre-pollute it with stale run state before saving (to prove the reset actually happens on load, not just on a never-run object), then load it back through the builder:

```smalltalk
AbOrchestrationGroupTest >> testOrchestrationLoadFromReturnsResetOrchestration [
	| orch path loaded builder group firstTopic |
	path := '/tmp/ab-test-orchestration-load.fuel'.
	orch := AbTopicOrchestration buildBy: [ :b |
		b seq: {
			b topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	firstTopic := orch steps first topicBuilders first topic.
	orch previousResult: 'stale-previous'.
	orch steps first stepResult: 'stale-step-result'.
	orch saveTo: path asFileReference.
	[
		group := AbOrchestrationGroup new.
		builder := AbOrchestrationGroupBuilder on: group.
		loaded := builder orchestrationLoadFrom: path asFileReference.
		self assert: (loaded isKindOf: AbTopicOrchestration).
		self assert: loaded previousResult isNil.
		self assert: loaded steps first stepResult isNil.
		self deny: loaded steps first topicBuilders first topic == firstTopic
	] ensure: [ path asFileReference ensureDelete ]
]

AbOrchestrationGroupTest >> testOrchestrationGroupLoadFromReturnsResetGroup [
	| innerOrch savedGroup path loaded builder group |
	path := '/tmp/ab-test-orchestration-group-load.fuel'.
	innerOrch := AbTopicOrchestration buildBy: [ :b |
		b seq: {
			b topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	savedGroup := AbOrchestrationGroup buildBy: [ :b |
		b seq: (OrderedCollection with: innerOrch) ].
	savedGroup previousResult: 'stale-previous'.
	innerOrch steps first stepResult: 'stale-step-result'.
	savedGroup saveTo: path asFileReference.
	[
		group := AbOrchestrationGroup new.
		builder := AbOrchestrationGroupBuilder on: group.
		loaded := builder orchestrationGroupLoadFrom: path asFileReference.
		self assert: (loaded isKindOf: AbOrchestrationGroup).
		self assert: loaded previousResult isNil.
		self assert: loaded steps first items first steps first stepResult isNil
	] ensure: [ path asFileReference ensureDelete ]
]

AbOrchestrationGroupTest >> testOrchestrationLoadFromCanBeAddedToSeq [
	| orch path loaded group |
	path := '/tmp/ab-test-orchestration-load-seq.fuel'.
	orch := AbTopicOrchestration buildBy: [ :b |
		b seq: {
			b topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: orch) ].
	group saveTo: path asFileReference.
	[
		| newGroup newBuilder |
		newGroup := AbOrchestrationGroup new.
		newBuilder := AbOrchestrationGroupBuilder on: newGroup.
		loaded := newBuilder orchestrationGroupLoadFrom: path asFileReference.
		newBuilder seq: (OrderedCollection with: loaded).
		self assert: newGroup steps size equals: 1.
		self assert: (newGroup steps first isKindOf: AbOrchestrationGroupSequentialStep).
		self assert: newGroup steps first items first equals: loaded
	] ensure: [ path asFileReference ensureDelete ]
]
```

**Note:** every item that can appear inside a saved `AbOrchestrationGroup` must respond to `resetForRerun` once Task 2 lands, since `AbOrchestrationGroupStep>>resetForRerun` unconditionally forwards to each item. `AbMockOrchestrationForGroup` (used elsewhere in `AbOrchestrationGroupTest` for lightweight run-order/timing tests) is never placed inside a group that gets `resetForRerun`'d, so it intentionally does not need the method — that's why this test uses a real `AbTopicOrchestration` instead.

- [ ] **Step 2: Run tests to verify they fail**

`st-import` the `AgenticBrowser-Scripting-Tests` package, then `st-test` on `AbOrchestrationGroupTest`. All three new tests must fail with `MessageNotUnderstood: orchestrationLoadFrom:` / `orchestrationGroupLoadFrom:`.

- [ ] **Step 3: Implement the builder methods**

In `src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st`, add next to the existing `orchestrationBy:`/`orchestrationGroupBy:` (category `'factory'`):

```smalltalk
{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationLoadFrom: aFileReference [
	^ (AbTopicOrchestration loadFrom: aFileReference)
		resetForRerun;
		yourself
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationGroupLoadFrom: aFileReference [
	^ (AbOrchestrationGroup loadFrom: aFileReference)
		resetForRerun;
		yourself
]
```

- [ ] **Step 4: Reimport and run tests, verify they pass**

`st-import` the modified `AgenticBrowser-Scripting` and `AgenticBrowser-Scripting-Tests` packages, then `st-test` on `AbOrchestrationGroupTest`. All three new tests must pass. Also run the full `AgenticBrowser-Scripting-Tests` package suite via `st-test` to confirm no regressions across the whole package.

- [ ] **Step 5: Update the class comment**

`AbOrchestrationGroupBuilder`'s class comment (top of `src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st`) currently lists the factory methods it provides. Add the two new methods to the "Responsibility" and "Public API and Key Messages" sections, following the existing bullet style, e.g.:

```
- Provide #orchestrationLoadFrom: to load a previously saved AbTopicOrchestration and reset it for a fresh run
- Provide #orchestrationGroupLoadFrom: to load a previously saved AbOrchestrationGroup and reset it for a fresh run
```

and in "Public API and Key Messages":

```
- #orchestrationLoadFrom: aFileReference - load a saved AbTopicOrchestration via Fuel and reset it (clears prior run results and cached topics) so it can be reused as a fresh item
- #orchestrationGroupLoadFrom: aFileReference - load a saved AbOrchestrationGroup via Fuel and reset it the same way
```

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st
git commit -m "Add orchestrationLoadFrom: and orchestrationGroupLoadFrom: to AbOrchestrationGroupBuilder"
```

---

## Final Verification

After Task 3, run the full test suite for the package one more time (`st-test` on `AgenticBrowser-Scripting-Tests`) to confirm all tests — old and new — pass together. Also update the checklist entry in `CLAUDE.local.md` (`- [ ] OrchestrationGroupBuilderに、...`) to checked, since this is user-tracked project state, not part of the source tree.
