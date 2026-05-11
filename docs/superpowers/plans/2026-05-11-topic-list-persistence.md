# Topic List Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist the `AbTopicManager default` topic list to `ab-topics.fuel` using Fuel serialization so topics survive image restarts.

**Architecture:** Add `fuelIgnoredInstanceVariableNames` class methods to exclude only external-resource instVars (network connections, lazy-init objects) from serialization. Fuel natively serializes blocks and object graphs including cycles, so `stateMachine` (with its entry-action blocks) and `whenAchievedBlock` serialize without any extra hooks. Add `saveTo:` / `loadFrom:` / `save` / `load` class methods to `AbTopicManager`.

**Tech Stack:** Pharo Smalltalk, Fuel (FLSerializer / FLMaterializer — built into Pharo), Tonel file format, SUnit tests.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/AgenticBrowser-Core/AbTopicManager.class.st` | Modify | Add `fuelIgnoredInstanceVariableNames`, persistence class methods |
| `src/AgenticBrowser-Core/AbTopic.class.st` | Modify | Add `fuelIgnoredInstanceVariableNames` to exclude lazy-init instVars |
| `src/AgenticBrowser-Core/AbTopicSession.class.st` | Modify | Add `fuelIgnoredInstanceVariableNames` to exclude `client` and `sessionId` |
| `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st` | Modify | Add persistence round-trip tests |

---

## Task 1: Exclude transient instVars from Fuel in AbTopicSession

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicSession.class.st`

### Context

`AbTopicSession` holds a live `ACPClient` (network socket) in `client` and a `sessionId` string. After materialization these should be nil so `ensureConnected` reconnects on demand — exactly what already happens when `client` is nil.

`whenAchievedBlock` in `AbTopicGoal`, and the `stateMachine` entry-action blocks in `AbTopic`, are serialized directly by Fuel — no exclusion needed.

- [ ] **Step 1.1: Write the failing test**

In `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`, add:

```smalltalk
testSessionClientAndSessionIdAreNilAfterFuelRoundTrip [

	| topic session bytes materialized |
	topic := AbTopic new title: 'Session round-trip'.
	session := topic session.
	"Simulate a connected state by manually setting non-nil stand-ins"
	session client: 'fake-client'.
	session sessionId: 'fake-session-id'.
	bytes := ByteArray streamContents: [ :s | FLSerializer newDefault serialize: topic on: s ].
	materialized := FLMaterializer newDefault materializeFrom: bytes readStream.
	self assert: materialized session client isNil.
	self assert: materialized session sessionId isNil
]
```

Run:
```
AbTopicManagerTest run: #testSessionClientAndSessionIdAreNilAfterFuelRoundTrip
```
Expected: FAIL (`client` is not excluded yet, so `'fake-client'` survives the round-trip).

- [ ] **Step 1.2: Add `fuelIgnoredInstanceVariableNames` to AbTopicSession**

In `src/AgenticBrowser-Core/AbTopicSession.class.st`, add this class method under a `'fuel'` category:

```smalltalk
{ #category : 'fuel' }
AbTopicSession class >> fuelIgnoredInstanceVariableNames [

	^ #( 'client' 'sessionId' )
]
```

- [ ] **Step 1.3: Import AgenticBrowser-Core and run the test**

Import the package, then run:
```
AbTopicManagerTest run: #testSessionClientAndSessionIdAreNilAfterFuelRoundTrip
```
Expected: PASS.

- [ ] **Step 1.4: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicSession.class.st \
        src/AgenticBrowser-Tests/AbTopicManagerTest.class.st
git commit -m "feat: exclude transient instVars from Fuel in AbTopicSession"
```

---

## Task 2: Exclude lazy-init instVars from Fuel in AbTopic

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`

### Context

`AbTopic` has several lazy-init instVars that are nil on first use and reconstructed on demand:
- `workingDirectory` — reconstructed from `workingDirectoryPath`
- `relatedPackagesWatcher` — reconstructed via the accessor
- `announcer` — reconstructed via the accessor
- `logger` — reconstructed via the accessor

Serializing these would capture stale subscription state (especially `relatedPackagesWatcher` which subscribes to `SystemAnnouncer`). Excluding them ensures clean reconstruction after materialization.

`stateMachine` is serialized as-is — Fuel handles the entry-action blocks and the cycle through `self` correctly, preserving current state.

- [ ] **Step 2.1: Write the failing tests**

In `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`, add:

```smalltalk
testTopicLazyInstVarsAreNilAfterFuelRoundTrip [

	| topic bytes materialized |
	topic := AbTopic new title: 'Lazy instVars'.
	"Force-create the lazy instVars so they are non-nil before serialization"
	topic announcer.
	topic workingDirectory.
	topic relatedPackagesWatcher.
	topic logger.
	bytes := ByteArray streamContents: [ :s | FLSerializer newDefault serialize: topic on: s ].
	materialized := FLMaterializer newDefault materializeFrom: bytes readStream.
	self assert: (materialized instVarNamed: 'announcer') isNil.
	self assert: (materialized instVarNamed: 'workingDirectory') isNil.
	self assert: (materialized instVarNamed: 'relatedPackagesWatcher') isNil.
	self assert: (materialized instVarNamed: 'logger') isNil
]

testTopicStatusIsPreservedAfterFuelRoundTrip [

	| topic bytes materialized |
	topic := AbTopic new title: 'Status round-trip'.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic status equals: #endTurn.
	bytes := ByteArray streamContents: [ :s | FLSerializer newDefault serialize: topic on: s ].
	materialized := FLMaterializer newDefault materializeFrom: bytes readStream.
	self assert: materialized status equals: #endTurn
]
```

Run:
```
AbTopicManagerTest run: #testTopicLazyInstVarsAreNilAfterFuelRoundTrip
AbTopicManagerTest run: #testTopicStatusIsPreservedAfterFuelRoundTrip
```
Expected: first test FAIL (lazy instVars survive the round-trip before exclusion). Second test may already PASS (Fuel serializes `stateMachine` correctly).

- [ ] **Step 2.2: Add `fuelIgnoredInstanceVariableNames` to AbTopic**

In `src/AgenticBrowser-Core/AbTopic.class.st`, add under a `'fuel'` category:

```smalltalk
{ #category : 'fuel' }
AbTopic class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' 'logger' 'workingDirectory' 'relatedPackagesWatcher' )
]
```

- [ ] **Step 2.3: Import AgenticBrowser-Core and run the tests**

Import the package, then run:
```
AbTopicManagerTest run: #testTopicLazyInstVarsAreNilAfterFuelRoundTrip
AbTopicManagerTest run: #testTopicStatusIsPreservedAfterFuelRoundTrip
```
Expected: both PASS.

- [ ] **Step 2.4: Run full test suite to check for regressions**

```
AbTopicManagerTest run.
AbTopicTest run.
AbTopicSessionTest run.
AbTopicGoalTest run.
```
Expected: all pass.

- [ ] **Step 2.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Tests/AbTopicManagerTest.class.st
git commit -m "feat: exclude lazy-init instVars from Fuel in AbTopic"
```

---

## Task 3: Add `fuelIgnoredInstanceVariableNames` to AbTopicManager and persistence methods

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicManager.class.st`

### Context

`AbTopicManager` has an `announcer` instVar that is lazy-init. Exclude it so restored managers start with a fresh announcer (the UI will re-subscribe on startup).

The persistence methods:
- `AbTopicManager class >> defaultPersistenceFile` → `Smalltalk imageDirectory / 'agentic-browser' / 'ab-topics.fuel'`
- `AbTopicManager class >> saveTo: aFileReference` → serialize `self default` with FLSerializer
- `AbTopicManager class >> loadFrom: aFileReference` → deserialize with FLMaterializer, return the loaded instance
- `AbTopicManager class >> save` → `self saveTo: self defaultPersistenceFile`
- `AbTopicManager class >> load` → replaces `default` classInstVar with the loaded instance

`load` replaces the `default` classInstVar. Callers must re-fetch `AbTopicManager default` after calling `load`.

- [ ] **Step 3.1: Write failing tests**

In `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`, add:

```smalltalk
testSaveToAndLoadFromRoundTrip [

	| manager topic file loaded |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Persisted topic'.
	manager addTopic: topic.
	file := FileReference newTempFilePrefix: 'ab-topics-test-' suffix: '.fuel'.
	[
	AbTopicManager saveTo: file manager: manager.
	loaded := AbTopicManager loadFrom: file.
	self assert: loaded topics size equals: 1.
	self assert: loaded topics first title equals: 'Persisted topic'.
	self assert: loaded topics first topicId equals: topic topicId ]
		ensure: [ file ensureDelete ]
]

testLoadFromRestoresTopicStatus [

	| manager topic file loaded |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'End turn topic'.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	manager addTopic: topic.
	file := FileReference newTempFilePrefix: 'ab-topics-status-' suffix: '.fuel'.
	[
	AbTopicManager saveTo: file manager: manager.
	loaded := AbTopicManager loadFrom: file.
	self assert: loaded topics first status equals: #endTurn ]
		ensure: [ file ensureDelete ]
]

testDefaultPersistenceFileIsInAgenticBrowserDirectory [

	| file |
	file := AbTopicManager defaultPersistenceFile.
	self assert: (file fullName includesSubstring: 'agentic-browser').
	self assert: (file fullName endsWith: 'ab-topics.fuel')
]
```

**Note:** `saveTo:manager:` is a test-friendly variant that accepts a manager argument so tests use `forTest` instead of `default`. The production `saveTo:` method saves `self default`.

Run:
```
AbTopicManagerTest run: #testSaveToAndLoadFromRoundTrip
```
Expected: FAIL (methods don't exist yet).

- [ ] **Step 3.2: Add `fuelIgnoredInstanceVariableNames` to AbTopicManager**

In `src/AgenticBrowser-Core/AbTopicManager.class.st`, add:

```smalltalk
{ #category : 'fuel' }
AbTopicManager class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' )
]
```

- [ ] **Step 3.3: Add `defaultPersistenceFile` class method**

```smalltalk
{ #category : 'persistence' }
AbTopicManager class >> defaultPersistenceFile [

	^ Smalltalk imageDirectory / 'agentic-browser' / 'ab-topics.fuel'
]
```

- [ ] **Step 3.4: Add `saveTo:manager:` (test helper) and `saveTo:` class methods**

```smalltalk
{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference manager: aManager [

	aFileReference parent ensureCreateDirectory.
	FLSerializer newDefault serialize: aManager toFileNamed: aFileReference fullName
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference [

	self saveTo: aFileReference manager: self default
]
```

- [ ] **Step 3.5: Add `loadFrom:` class method**

```smalltalk
{ #category : 'persistence' }
AbTopicManager class >> loadFrom: aFileReference [

	^ FLMaterializer newDefault materializeFromFileNamed: aFileReference fullName
]
```

- [ ] **Step 3.6: Add `save` and `load` convenience class methods**

```smalltalk
{ #category : 'persistence' }
AbTopicManager class >> save [

	self saveTo: self defaultPersistenceFile
]

{ #category : 'persistence' }
AbTopicManager class >> load [

	default := self loadFrom: self defaultPersistenceFile
]
```

- [ ] **Step 3.7: Import AgenticBrowser-Core and run tests**

Import the package, then:
```
AbTopicManagerTest run: #testSaveToAndLoadFromRoundTrip
AbTopicManagerTest run: #testLoadFromRestoresTopicStatus
AbTopicManagerTest run: #testDefaultPersistenceFileIsInAgenticBrowserDirectory
```
Expected: all PASS.

- [ ] **Step 3.8: Run full test suite**

```
AbTopicManagerTest run.
AbTopicTest run.
```
Expected: all pass (no regressions).

- [ ] **Step 3.9: Smoke test in image**

In a Pharo Playground, run:
```smalltalk
| topic |
topic := AbTopic new title: 'Smoke test topic'.
AbTopicManager default addTopic: topic.
AbTopicManager save.
AbTopicManager load.
AbTopicManager default topics first title "→ 'Smoke test topic'"
```
Expected: the title prints correctly.

- [ ] **Step 3.10: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicManager.class.st \
        src/AgenticBrowser-Tests/AbTopicManagerTest.class.st
git commit -m "feat: add Fuel persistence to AbTopicManager (saveTo:, loadFrom:, save, load)"
```

---

## Self-Review

### Spec coverage check

| Requirement | Covered by |
|-------------|-----------|
| Save `AbTopicManager default` to `ab-topics.fuel` | Task 3, `save` method |
| Restore from `ab-topics.fuel` | Task 3, `load` method |
| `AbTopicManager saveTo: fileReference` class method | Task 3, Step 3.4 |
| `AbTopicManager loadFrom: fileReference` class method | Task 3, Step 3.5 |
| `AbTopicManager save` (default path) | Task 3, Step 3.6 |
| `AbTopicManager load` (default path) | Task 3, Step 3.6 |
| Default location: `<imageDir>/agentic-browser/ab-topics.fuel` | Task 3, Step 3.3 |
| Fuel format | All tasks — FLSerializer/FLMaterializer |
| `client`/socket excluded | Task 1 — AbTopicSession |
| `workingDirectory` excluded (path string persisted) | Task 2 — AbTopic |
| State machine preserved | Fuel serializes it natively (no special handling) |
| `whenAchievedBlock` preserved | Fuel serializes it natively (no special handling) |

### No placeholders — all code is concrete.

### Type consistency
- `saveTo: aFileReference` / `saveTo:manager:` both take a `FileReference`
- `loadFrom: aFileReference` returns an `AbTopicManager` instance
- `save` / `load` operate on `self default`; `load` replaces `default` classInstVar

All method names consistent across tasks.
