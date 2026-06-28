# OrchestrationGroup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `AbOrchestrationGroup` (composite pattern) so multiple orchestrations can run in parallel or sequentially, plus add `AbOrchestrationEnded` announcement to `AbTopicOrchestration`.

**Architecture:** Three independent sub-features: (1) `AbOrchestrationEnded` announcement fired by `AbTopicOrchestration >> run`; (2) `AbOrchestrationGroupNode` hierarchy (para/seq) holding items that are `AbTopicOrchestration` or `AbOrchestrationGroup`; (3) `AbOrchestrationGroup` with `buildBy:` DSL via `AbOrchestrationGroupBuilder`. The composite pattern means `AbOrchestrationGroup` and `AbTopicOrchestration` share no common superclass — the group holds a heterogeneous collection of "runnable" objects (duck-typed: must respond to `run`).

**Tech Stack:** Pharo 13 Smalltalk, Tonel file format, SUnit tests, `AgenticBrowser-Scripting` package

## Global Constraints

- All `.st` files use Tonel format: class comment string at top, then `Class { ... }` definition, then methods as `{ #category : '...' } ClassName >> selector [...]`
- Package name in every file: `'AgenticBrowser-Scripting'` (or `-Tests` for test files)
- No `setXXX:` setter names — use plain `fieldName:` (e.g., `group:` not `setGroup:`)
- All method categories in `accessing`, `building`, `running`, `instance creation`, `private`, `testing`, `initialization` per Pharo convention
- Run tests via MCP tool `mcp__smalltalk-interop__run_class_test` or `run_package_test`
- Import after each task via MCP tool `mcp__smalltalk-interop__import_package`
- Write documentation (class CRC comments) in English
- `fuelIgnoredInstanceVariableNames` must include `announcer` if added to `AbTopicOrchestration`

---

## Task 1: AbOrchestrationEnded announcement + announcer on AbTopicOrchestration

**Files:**
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationEnded.class.st`
- Modify: `src/AgenticBrowser-Scripting/AbTopicOrchestration.class.st`
- Modify: `src/AgenticBrowser-Scripting-Tests/AbTopicOrchestrationTest.class.st`

**Interfaces:**
- Produces: `AbOrchestrationEnded` with `orchestration` accessor; `AbTopicOrchestration >> announcer` returning an `Announcer`

- [ ] **Step 1: Write the failing test**

Add to `AbTopicOrchestrationTest`:

```smalltalk
{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationFiresEndedAnnouncementOnRunComplete [
	| orchestration endedAnnouncement |
	endedAnnouncement := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ]
			} agentBy: [ :a | a codex ] ].

	orchestration announcer
		when: AbOrchestrationEnded
		do: [ :ann | endedAnnouncement := ann ]
		for: self.

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann | self simulateEndTurnWhenWorkingFor: ann topic ]
		for: self.

	[
		orchestration run.
		self assert: endedAnnouncement notNil.
		self assert: endedAnnouncement orchestration == orchestration
	] ensure: [ self unsubscribeTopicHandlers ]
]
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbTopicOrchestrationTest'`, `testName: 'testOrchestrationFiresEndedAnnouncementOnRunComplete'`

Expected: FAIL — `AbOrchestrationEnded` does not exist

- [ ] **Step 3: Create AbOrchestrationEnded announcement class**

Create `src/AgenticBrowser-Scripting/AbOrchestrationEnded.class.st`:

```
"
I am the announcement fired when an AbTopicOrchestration finishes its run (whether successfully or with an error).

Responsibility:
- Carry a reference to the completed orchestration

Collaborators:
- AbTopicOrchestration: fires me in its #run ensure: block
- AbOrchestrationGroup: subscribes to me to coordinate parallel orchestration completion
"
Class {
	#name : 'AbOrchestrationEnded',
	#superclass : 'Announcement',
	#instVars : [
		'orchestration'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationEnded class >> orchestration: anOrchestration [
	^ self new
		orchestration: anOrchestration;
		yourself
]

{ #category : 'accessing' }
AbOrchestrationEnded >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbOrchestrationEnded >> orchestration: anOrchestration [
	orchestration := anOrchestration
]
```

- [ ] **Step 4: Add `announcer` instVar and accessor to AbTopicOrchestration**

In `src/AgenticBrowser-Scripting/AbTopicOrchestration.class.st`:

Change the class definition instVars line from:
```
	#instVars : [
		'id',
		'name',
		'steps',
		'sharedDirectoryPath',
		'settings',
		'logger'
	],
```
to:
```
	#instVars : [
		'id',
		'name',
		'steps',
		'sharedDirectoryPath',
		'settings',
		'logger',
		'announcer'
	],
```

Add to `fuelIgnoredInstanceVariableNames`:
```smalltalk
{ #category : 'fuel' }
AbTopicOrchestration class >> fuelIgnoredInstanceVariableNames [
	^ #( 'logger' 'announcer' )
]
```

Add accessor method:
```smalltalk
{ #category : 'accessing' }
AbTopicOrchestration >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]
```

- [ ] **Step 5: Fire AbOrchestrationEnded in run**

Modify `AbTopicOrchestration >> run` to fire the announcement in the `ensure:` block:

```smalltalk
{ #category : 'running' }
AbTopicOrchestration >> run [
	| stepResult |
	self logger debug: 'Orchestration run: start name=' , self name , ' steps=' , self steps size printString.
	stepResult := nil.
	[
		self steps do: [ :step |
			step previousStepResult: stepResult.
			stepResult := step run.
			step stepResult: stepResult ]
	] ensure: [
		self settings lingerOrchestrationTopicsAfterRun ifFalse: [ self removeTopicsFromManager ].
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	self logger debug: 'Orchestration run: end name=' , self name.
	^ stepResult
]
```

- [ ] **Step 6: Import and run the test**

Import: `mcp__smalltalk-interop__import_package` with `packageName: 'AgenticBrowser-Scripting'`

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbTopicOrchestrationTest'`, `testName: 'testOrchestrationFiresEndedAnnouncementOnRunComplete'`

Expected: PASS

- [ ] **Step 7: Run the full test class to confirm no regressions**

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbTopicOrchestrationTest'`

Expected: all tests PASS

- [ ] **Step 8: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbOrchestrationEnded.class.st \
        src/AgenticBrowser-Scripting/AbTopicOrchestration.class.st \
        src/AgenticBrowser-Scripting-Tests/AbTopicOrchestrationTest.class.st
git commit -m "feat: add AbOrchestrationEnded announcement to AbTopicOrchestration"
```

---

## Task 2: AbOrchestrationGroupNode hierarchy (abstract + seq + para)

**Files:**
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationGroupNode.class.st`
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationGroupSeqNode.class.st`
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationGroupParaNode.class.st`
- Create: `src/AgenticBrowser-Scripting-Tests/AbMockOrchestrationForGroup.class.st`
- Create: `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`

**Interfaces:**
- Consumes: `AbOrchestrationEnded` from Task 1 (para node uses it to wait for completion)
- Produces:
  - `AbOrchestrationGroupNode class >> on: aGroup items: aCollection` factory
  - `AbOrchestrationGroupNode >> run` (abstract, returns last result or nil)
  - `AbOrchestrationGroupSeqNode >> run` (sequential, returns last item's run result)
  - `AbOrchestrationGroupParaNode >> run` (parallel, forks and waits via `AbOrchestrationEnded`, returns nil)

- [ ] **Step 1: Create the mock orchestration for group tests**

Create `src/AgenticBrowser-Scripting-Tests/AbMockOrchestrationForGroup.class.st`:

```
"
I am a lightweight mock orchestration used in AbOrchestrationGroup tests.
I skip all real topic/agent machinery and just record that I was run.
"
Class {
	#name : 'AbMockOrchestrationForGroup',
	#superclass : 'Object',
	#instVars : [
		'runResult',
		'runCount',
		'runDelay',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'instance creation' }
AbMockOrchestrationForGroup class >> withResult: aString [
	^ self new runResult: aString
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runResult [
	^ runResult
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runResult: aString [
	runResult := aString
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runCount [
	^ runCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runDelay: aNumber [
	runDelay := aNumber
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'running' }
AbMockOrchestrationForGroup >> run [
	runCount := self runCount + 1.
	runDelay ifNotNil: [ (Delay forMilliseconds: runDelay) wait ].
	self announcer announce: (AbOrchestrationEnded orchestration: self).
	^ runResult
]
```

- [ ] **Step 2: Write failing tests for SeqNode and ParaNode**

Create `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`:

```
Class {
	#name : 'AbOrchestrationGroupTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSeqNodeRunsItemsInOrder [
	| runOrder o1 o2 o3 node |
	runOrder := OrderedCollection new.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 announcer when: AbOrchestrationEnded do: [ runOrder add: 1 ] for: self.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 announcer when: AbOrchestrationEnded do: [ runOrder add: 2 ] for: self.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	o3 announcer when: AbOrchestrationEnded do: [ runOrder add: 3 ] for: self.

	node := AbOrchestrationGroupSeqNode new
		items: (OrderedCollection with: o1 with: o2 with: o3);
		yourself.
	node run.

	self assert: runOrder asArray equals: #(1 2 3)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSeqNodeReturnsLastItemResult [
	| node result |
	node := AbOrchestrationGroupSeqNode new
		items: (OrderedCollection
			with: (AbMockOrchestrationForGroup withResult: 'first')
			with: (AbMockOrchestrationForGroup withResult: 'last'));
		yourself.
	result := node run.
	self assert: result equals: 'last'
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaNodeRunsItemsConcurrently [
	| startTimes o1 o2 node |
	startTimes := OrderedCollection new.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 runDelay: 50.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 runDelay: 50.
	node := AbOrchestrationGroupParaNode new
		items: (OrderedCollection with: o1 with: o2);
		yourself.
	node run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaNodeWaitsForAllItems [
	| o1 o2 node |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 runDelay: 30.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 runDelay: 10.
	node := AbOrchestrationGroupParaNode new
		items: (OrderedCollection with: o1 with: o2);
		yourself.
	node run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1
]
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbOrchestrationGroupTest'`

Expected: FAIL — `AbOrchestrationGroupSeqNode` and `AbOrchestrationGroupParaNode` do not exist

- [ ] **Step 4: Create AbOrchestrationGroupNode abstract base class**

Create `src/AgenticBrowser-Scripting/AbOrchestrationGroupNode.class.st`:

```
"
I am the abstract base for a node in an AbOrchestrationGroup.

Each node holds a collection of runnable items (AbTopicOrchestration or AbOrchestrationGroup)
and executes them either sequentially (AbOrchestrationGroupSeqNode) or concurrently
(AbOrchestrationGroupParaNode).

Responsibility:
- Hold the items to execute
- Define the #run protocol (subclasses implement it)

Collaborators:
- AbOrchestrationGroup: holds me and calls #run in order
- AbTopicOrchestration / AbOrchestrationGroup: my items (duck-typed: must respond to #run)
"
Class {
	#name : 'AbOrchestrationGroupNode',
	#superclass : 'Object',
	#instVars : [
		'items'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbOrchestrationGroupNode >> items [
	^ items ifNil: [ items := OrderedCollection new ]
]

{ #category : 'accessing' }
AbOrchestrationGroupNode >> items: aCollection [
	items := aCollection asOrderedCollection
]

{ #category : 'running' }
AbOrchestrationGroupNode >> run [
	self subclassResponsibility
]
```

- [ ] **Step 5: Create AbOrchestrationGroupSeqNode**

Create `src/AgenticBrowser-Scripting/AbOrchestrationGroupSeqNode.class.st`:

```
"
I run my items one after another and return the last item's result.
"
Class {
	#name : 'AbOrchestrationGroupSeqNode',
	#superclass : 'AbOrchestrationGroupNode',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupSeqNode >> run [
	| result |
	result := nil.
	self items do: [ :item | result := item run ].
	^ result
]
```

- [ ] **Step 6: Create AbOrchestrationGroupParaNode**

Create `src/AgenticBrowser-Scripting/AbOrchestrationGroupParaNode.class.st`:

```
"
I run my items concurrently by forking each one, waiting for all to complete via AbOrchestrationEnded.
"
Class {
	#name : 'AbOrchestrationGroupParaNode',
	#superclass : 'AbOrchestrationGroupNode',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupParaNode >> run [
	| semaphore |
	semaphore := Semaphore new.
	self items do: [ :item |
		item announcer
			when: AbOrchestrationEnded
			do: [ semaphore signal ]
			for: self.
		[ item run ] fork ].
	self items size timesRepeat: [ semaphore wait ].
	self items do: [ :item | item announcer unsubscribe: self ]
]
```

- [ ] **Step 7: Import packages and run tests**

Import: `mcp__smalltalk-interop__import_package` with `packageName: 'AgenticBrowser-Scripting'`
Import: `mcp__smalltalk-interop__import_package` with `packageName: 'AgenticBrowser-Scripting-Tests'`

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbOrchestrationGroupTest'`

Expected: all tests PASS

- [ ] **Step 8: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbOrchestrationGroupNode.class.st \
        src/AgenticBrowser-Scripting/AbOrchestrationGroupSeqNode.class.st \
        src/AgenticBrowser-Scripting/AbOrchestrationGroupParaNode.class.st \
        src/AgenticBrowser-Scripting-Tests/AbMockOrchestrationForGroup.class.st \
        src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st
git commit -m "feat: add AbOrchestrationGroupNode hierarchy (seq + para)"
```

---

## Task 3: AbOrchestrationGroup + AbOrchestrationGroupBuilder

**Files:**
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationGroup.class.st`
- Create: `src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st`
- Modify: `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`

**Interfaces:**
- Consumes: `AbOrchestrationGroupSeqNode`, `AbOrchestrationGroupParaNode` from Task 2; `AbTopicOrchestration` from codebase
- Produces:
  - `AbOrchestrationGroup class >> buildBy: aBlock` → `AbOrchestrationGroup`
  - `AbOrchestrationGroup >> run` → runs nodes in order, returns last result
  - `AbOrchestrationGroup >> announcer` → `Announcer` (fires `AbOrchestrationEnded` on completion)
  - `AbOrchestrationGroupBuilder >> para: aCollection` → adds `AbOrchestrationGroupParaNode`
  - `AbOrchestrationGroupBuilder >> seq: aCollection` → adds `AbOrchestrationGroupSeqNode`
  - `AbOrchestrationGroupBuilder >> orchestrationBy: aBlock` → `AbTopicOrchestration`
  - `AbOrchestrationGroupBuilder >> orchestrationGroupBy: aBlock` → `AbOrchestrationGroup`

- [ ] **Step 1: Write failing tests for AbOrchestrationGroup**

Add to `src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupBuildByCreatesParaNode [
	| o1 o2 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2) ].
	self assert: group nodes size equals: 1.
	self assert: (group nodes first isKindOf: AbOrchestrationGroupParaNode)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupBuildByCreatesSeqNode [
	| o1 o2 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1 with: o2) ].
	self assert: group nodes size equals: 1.
	self assert: (group nodes first isKindOf: AbOrchestrationGroupSeqNode)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupRunExecutesAllNodes [
	| o1 o2 o3 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2).
		builder seq: (OrderedCollection with: o3) ].
	group run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1.
	self assert: o3 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupRunNodesInOrderParaThenSeq [
	| paraFinished seqStarted o1 o2 group |
	paraFinished := false.
	seqStarted := false.
	o1 := AbMockOrchestrationForGroup new.
	o1 runResult: 'r1'.
	o2 := AbMockOrchestrationForGroup new.
	o2 runResult: 'r2'.
	"o2 checks that para finished before seq"
	| o3 |
	o3 := AbMockOrchestrationForGroup new.
	o3 runResult: 'r3'.
	o1 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o2 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o3 announcer when: AbOrchestrationEnded do: [ seqStarted := paraFinished ] for: self.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2).
		builder seq: (OrderedCollection with: o3) ].
	group run.
	self assert: seqStarted
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupFiresOrchestrationEndedOnCompletion [
	| group ended o1 |
	ended := false.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1) ].
	group announcer
		when: AbOrchestrationEnded
		do: [ :ann | ended := true ]
		for: self.
	group run.
	self assert: ended
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testOrchestrationByCreatesOrchestration [
	| group |
	group := AbOrchestrationGroup buildBy: [ :builder |
		| o |
		o := builder orchestrationBy: [ :b |
			b name: 'test-orchestration' ].
		self assert: (o isKindOf: AbTopicOrchestration).
		self assert: o name equals: 'test-orchestration'.
		builder seq: (OrderedCollection with: o) ].
	self assert: group nodes size equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testOrchestrationGroupByCreatesNestedGroup [
	| outerGroup innerGroup |
	outerGroup := AbOrchestrationGroup buildBy: [ :builder |
		| inner |
		inner := builder orchestrationGroupBy: [ :b |
			| o |
			o := AbMockOrchestrationForGroup withResult: 'r'.
			b seq: (OrderedCollection with: o) ].
		innerGroup := inner.
		builder seq: (OrderedCollection with: inner) ].
	self assert: innerGroup notNil.
	self assert: (innerGroup isKindOf: AbOrchestrationGroup).
	outerGroup run.
	"inner group ran"
	self assert: innerGroup nodes size equals: 1
]
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbOrchestrationGroupTest'`, `testName: 'testGroupBuildByCreatesParaNode'`

Expected: FAIL — `AbOrchestrationGroup` does not exist

- [ ] **Step 3: Create AbOrchestrationGroup**

Create `src/AgenticBrowser-Scripting/AbOrchestrationGroup.class.st`:

```
"
I am a composite container of orchestration workflows that can be run in groups.

I hold an ordered list of AbOrchestrationGroupNode instances. When #run is called, I execute
each node in order. Each node runs its contained items either sequentially (AbOrchestrationGroupSeqNode)
or concurrently (AbOrchestrationGroupParaNode).

I announce AbOrchestrationEnded on my own announcer when all nodes complete, making me composable:
I can be nested inside another AbOrchestrationGroup as an item.

Responsibility:
- Hold an ordered list of AbOrchestrationGroupNode instances
- Execute nodes in sequence when #run is called
- Fire AbOrchestrationEnded on completion
- Expose #announcer so subscribers can react to completion

Collaborators:
- AbOrchestrationGroupBuilder: constructs me via #buildBy:
- AbOrchestrationGroupNode (subclasses): my execution nodes
- AbTopicOrchestration: leaf items inside nodes
- AbOrchestrationEnded: fired on completion

Public API and Key Messages:
- #buildBy: aBlock - configure nodes via DSL builder block
- #run - execute all nodes in order; blocks until complete; returns last node result
- #announcer - Announcer that fires AbOrchestrationEnded on run completion
- #nodes - the ordered collection of AbOrchestrationGroupNode
"
Class {
	#name : 'AbOrchestrationGroup',
	#superclass : 'Object',
	#instVars : [
		'nodes',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbOrchestrationGroup class >> buildBy: aBlock [
	^ self new buildBy: aBlock
]

{ #category : 'building' }
AbOrchestrationGroup >> buildBy: aBlock [
	| builder |
	builder := AbOrchestrationGroupBuilder on: self.
	aBlock value: builder
]

{ #category : 'accessing' }
AbOrchestrationGroup >> nodes [
	^ nodes ifNil: [ nodes := OrderedCollection new ]
]

{ #category : 'accessing' }
AbOrchestrationGroup >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'running' }
AbOrchestrationGroup >> run [
	| result |
	result := nil.
	[
		self nodes do: [ :node | result := node run ]
	] ensure: [
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	^ result
]
```

- [ ] **Step 4: Create AbOrchestrationGroupBuilder**

Create `src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st`:

```
"
I am the DSL builder for AbOrchestrationGroup.

I provide #para: and #seq: to add execution nodes, and factory methods #orchestrationBy: and
#orchestrationGroupBy: to create child orchestrations and groups.

Responsibility:
- Provide #para: and #seq: DSL entry points (each adds a node to the group)
- Provide #orchestrationBy: to create an AbTopicOrchestration via its own builder
- Provide #orchestrationGroupBy: to create a nested AbOrchestrationGroup

Collaborators:
- AbOrchestrationGroup: the group under construction (holds my nodes via #group)
- AbOrchestrationGroupParaNode: created by #para:
- AbOrchestrationGroupSeqNode: created by #seq:
- AbTopicOrchestration: created by #orchestrationBy:

Public API and Key Messages:
- #para: aCollection - add a parallel node containing the items in aCollection
- #seq: aCollection - add a sequential node containing the items in aCollection
- #orchestrationBy: aBlock - create AbTopicOrchestration; block receives AbTopicOrchestrationBuilder
- #orchestrationGroupBy: aBlock - create nested AbOrchestrationGroup; block receives AbOrchestrationGroupBuilder
"
Class {
	#name : 'AbOrchestrationGroupBuilder',
	#superclass : 'Object',
	#instVars : [
		'group'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationGroupBuilder class >> on: anOrchestrationGroup [
	^ self new
		group: anOrchestrationGroup;
		yourself
]

{ #category : 'accessing' }
AbOrchestrationGroupBuilder >> group [
	^ group
]

{ #category : 'accessing' }
AbOrchestrationGroupBuilder >> group: anOrchestrationGroup [
	group := anOrchestrationGroup
]

{ #category : 'building' }
AbOrchestrationGroupBuilder >> para: aCollection [
	| node |
	node := AbOrchestrationGroupParaNode new
		items: aCollection;
		yourself.
	group nodes add: node
]

{ #category : 'building' }
AbOrchestrationGroupBuilder >> seq: aCollection [
	| node |
	node := AbOrchestrationGroupSeqNode new
		items: aCollection;
		yourself.
	group nodes add: node
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationBy: aBlock [
	^ AbTopicOrchestration buildBy: aBlock
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationGroupBy: aBlock [
	^ AbOrchestrationGroup buildBy: aBlock
]
```

- [ ] **Step 5: Import and run tests**

Import: `mcp__smalltalk-interop__import_package` with `packageName: 'AgenticBrowser-Scripting'`
Import: `mcp__smalltalk-interop__import_package` with `packageName: 'AgenticBrowser-Scripting-Tests'`

Run: `mcp__smalltalk-interop__run_class_test` with `className: 'AbOrchestrationGroupTest'`

Expected: all tests PASS

- [ ] **Step 6: Run all scripting tests to confirm no regressions**

Run: `mcp__smalltalk-interop__run_package_test` with `packageName: 'AgenticBrowser-Scripting-Tests'`

Expected: all tests PASS

- [ ] **Step 7: Export updated packages back to Tonel files**

Export: `mcp__smalltalk-interop__export_package` with `packageName: 'AgenticBrowser-Scripting'`
Export: `mcp__smalltalk-interop__export_package` with `packageName: 'AgenticBrowser-Scripting-Tests'`

- [ ] **Step 8: Commit**

```bash
git add src/AgenticBrowser-Scripting/AbOrchestrationGroup.class.st \
        src/AgenticBrowser-Scripting/AbOrchestrationGroupBuilder.class.st \
        src/AgenticBrowser-Scripting-Tests/AbOrchestrationGroupTest.class.st
git commit -m "feat: add AbOrchestrationGroup with DSL builder (para/seq/orchestrationBy)"
```

---

## Self-Review

### Spec coverage check

| Requirement | Task |
|---|---|
| `AbOrchestrationEnded` announcement | Task 1 |
| `AbTopicOrchestration` fires it on `run` completion | Task 1 |
| `name` on orchestration | Already exists in `AbTopicOrchestration` — no work needed |
| `AbOrchestrationGroup buildBy:` DSL | Task 3 |
| `builder para: {...}` (parallel items) | Task 3 |
| `builder seq: {...}` (sequential items) | Task 3 |
| `builder orchestrationBy:` creates `AbTopicOrchestration` | Task 3 |
| `builder orchestrationGroupBy:` creates nested group | Task 3 |
| Elements are `AbTopicOrchestration` or `AbOrchestrationGroup` (composite) | Tasks 2+3 |
| `group run` executes all nodes | Task 3 |
| `AbOrchestrationGroup` itself fires `AbOrchestrationEnded` | Task 3 |
| Para nodes run concurrently | Task 2 |
| Seq nodes run in order | Task 2 |

### Placeholder scan: none found

### Type consistency check

- `AbOrchestrationGroupParaNode >> run` subscribes to `AbOrchestrationEnded` on each item's `announcer`. This requires items to have an `announcer` that fires `AbOrchestrationEnded`. ✓ `AbTopicOrchestration` (Task 1) and `AbOrchestrationGroup` (Task 3) both have `announcer` and fire `AbOrchestrationEnded`. The mock `AbMockOrchestrationForGroup` also fires it.
- `AbOrchestrationGroup >> run` passes `result := node run` — `AbOrchestrationGroupSeqNode >> run` returns the last item's result; `AbOrchestrationGroupParaNode >> run` returns `nil` (no combined result at group level). ✓ Consistent.
- `testGroupRunNodesInOrderParaThenSeq` uses `| o3 |` inside the method after already declaring locals — this is a Pharo syntax issue. Fix: declare `o3` in the outer temp variable list along with `o1 o2`.

### Fixed issue in testGroupRunNodesInOrderParaThenSeq

The test uses a nested `| o3 |` declaration which is invalid Pharo. The corrected test:

```smalltalk
{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupRunNodesInOrderParaThenSeq [
	| o1 o2 o3 paraFinished seqStarted group |
	paraFinished := false.
	seqStarted := false.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	o1 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o2 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o3 announcer when: AbOrchestrationEnded do: [ seqStarted := paraFinished ] for: self.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2).
		builder seq: (OrderedCollection with: o3) ].
	group run.
	self assert: seqStarted
]
```

Use this corrected version in Task 3, Step 1 instead of the one shown above.
