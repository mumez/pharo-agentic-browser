# Queue-Based Package Change Processing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace synchronous class-change handling in `AbTopicRelatedPackagesWatcher` with a SharedQueue + worker process so that SystemAnnouncer callbacks return immediately and processing happens on a dedicated background thread.

**Architecture:** `handleClassChangeNamed:in:` enqueues an `Association (className -> packageName)` into a `SharedQueue`; a single worker process started by `start` dequeues items and calls `doHandleClassChange:in:`. `stop` sends a `nil` sentinel to wake the blocking `next` call, then terminates the worker process.

**Tech Stack:** Pharo 13, SharedQueue, Process (Processor userBackgroundPriority), SUnit

---

## File Map

| File | Change |
|------|--------|
| `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st` | Add `changeQueue`, `workerProcess` instVars; modify `handleClassChangeNamed:in:`, `start`, `stop`; add `runWorkerLoop` |
| `src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st` | Add tests for queue enqueue, worker lifecycle, stop sentinel |

---

## Task 1: Add instVars and update `initialize`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`

- [ ] **Step 1: Add `changeQueue` and `workerProcess` to instVars**

Replace the class header's `instVars` array:

```
#instVars : [
    'topic',
    'isWatching',
    'lastAnnouncedAtByPackage',
    'logger',
    'changeQueue',
    'workerProcess'
],
```

- [ ] **Step 2: Initialize `changeQueue` in `initialize`**

```smalltalk
{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	self isWatching: false.
	lastAnnouncedAtByPackage := Dictionary new.
	changeQueue := SharedQueue new
]
```

- [ ] **Step 3: Import and verify no errors**

```
/st-import AgenticBrowser-Core /home/mumez/git/pharo-agentic-browser/src
```

Expected: import succeeds with no errors.

---

## Task 2: Write failing tests for queue enqueue behavior

**Files:**
- Modify: `src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st`

- [ ] **Step 1: Write test — `handleClassChangeNamed:in:` enqueues instead of processing synchronously**

Add to the test class:

```smalltalk
{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeNamedEnqueuesItem [

	watcher handleClassChangeNamed: 'MyClass' in: 'MyPkg'.
	self assert: watcher changeQueue size equals: 1.
	self assert: watcher changeQueue next equals: 'MyClass' -> 'MyPkg'
]
```

- [ ] **Step 2: Write test — multiple enqueues preserve FIFO order**

```smalltalk
{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeNamedEnqueuesInFifoOrder [

	watcher handleClassChangeNamed: 'ClassA' in: 'Pkg1'.
	watcher handleClassChangeNamed: 'ClassB' in: 'Pkg2'.
	self assert: watcher changeQueue next equals: 'ClassA' -> 'Pkg1'.
	self assert: watcher changeQueue next equals: 'ClassB' -> 'Pkg2'
]
```

- [ ] **Step 3: Add `changeQueue` accessor to watcher (needed for tests)**

```smalltalk
{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> changeQueue [
	^ changeQueue
]
```

- [ ] **Step 4: Import both packages**

```
/st-import AgenticBrowser-Core /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
```

- [ ] **Step 5: Run tests — verify they FAIL**

```
/st-test AbTopicRelatedPackagesWatcherTest
```

Expected: `testHandleClassChangeNamedEnqueuesItem` and `testHandleClassChangeNamedEnqueuesInFifoOrder` fail because `handleClassChangeNamed:in:` still calls `doHandleClassChange:in:` directly.

---

## Task 3: Implement enqueue in `handleClassChangeNamed:in:`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`

- [ ] **Step 1: Change `handleClassChangeNamed:in:` to enqueue**

```smalltalk
{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleClassChangeNamed: aClassName in: aPackageName [

	changeQueue nextPut: aClassName -> aPackageName
]
```

- [ ] **Step 2: Import and run the new tests**

```
/st-import AgenticBrowser-Core /home/mumez/git/pharo-agentic-browser/src
/st-test AbTopicRelatedPackagesWatcherTest
```

Expected: `testHandleClassChangeNamedEnqueuesItem` and `testHandleClassChangeNamedEnqueuesInFifoOrder` pass.

- [ ] **Step 3: Run full test suite — verify no regressions**

```
/st-test AgenticBrowser-Tests
```

Expected: all previously passing tests still pass.

---

## Task 4: Write failing tests for worker process lifecycle

**Files:**
- Modify: `src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st`

- [ ] **Step 1: Write test — `start` creates a live worker process**

```smalltalk
{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStartCreatesWorkerProcess [

	watcher start.
	self assert: watcher workerProcess notNil.
	self assert: watcher workerProcess isTerminated not
]
```

- [ ] **Step 2: Write test — `stop` terminates the worker process**

```smalltalk
{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStopTerminatesWorkerProcess [

	watcher start.
	watcher stop.
	self assert: watcher workerProcess isTerminated
]
```

- [ ] **Step 3: Add `workerProcess` accessor**

```smalltalk
{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> workerProcess [
	^ workerProcess
]
```

- [ ] **Step 4: Import and run — verify tests FAIL**

```
/st-import AgenticBrowser-Core /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbTopicRelatedPackagesWatcherTest
```

Expected: `testStartCreatesWorkerProcess` and `testStopTerminatesWorkerProcess` fail.

---

## Task 5: Implement `runWorkerLoop`, update `start` and `stop`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`

- [ ] **Step 1: Add `runWorkerLoop`**

```smalltalk
{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> runWorkerLoop [

	[ isWatching ] whileTrue: [
		| item |
		item := changeQueue next.
		item ifNotNil: [
			self doHandleClassChange: item key in: item value ] ]
]
```

- [ ] **Step 2: Update `start` to create queue and spawn worker**

```smalltalk
{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

	changeQueue := SharedQueue new.
	self isWatching: true.
	workerProcess := [ self runWorkerLoop ] newProcess
		name: 'AgenticBrowser package watcher';
		priority: Processor userBackgroundPriority;
		yourself.
	workerProcess resume.
	SystemAnnouncer uniqueInstance
		when: MethodAnnouncement
		do: [ :ann | self handleMethodChange: ann ]
		for: self.
	SystemAnnouncer uniqueInstance
		when: ClassAnnouncement
		do: [ :ann | self handleClassChange: ann ]
		for: self
]
```

- [ ] **Step 3: Update `stop` to signal worker via sentinel**

```smalltalk
{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	self isWatching: false.
	changeQueue nextPut: nil.
	workerProcess ifNotNil: [ :p | p terminate ].
	workerProcess := nil
]
```

- [ ] **Step 4: Import and run lifecycle tests**

```
/st-import AgenticBrowser-Core /home/mumez/git/pharo-agentic-browser/src
/st-test AbTopicRelatedPackagesWatcherTest
```

Expected: `testStartCreatesWorkerProcess` and `testStopTerminatesWorkerProcess` pass.

- [ ] **Step 5: Run full test suite**

```
/st-test AgenticBrowser-Tests
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st \
        src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st
git commit -m "feat: queue-based class change processing in AbTopicRelatedPackagesWatcher"
```

---

## Task 6: Integration smoke test

- [ ] **Step 1: Open browser and verify watcher starts without error**

```smalltalk
AbBrowserPresenter open
```

Read screen to confirm the window opens without a debugger.

- [ ] **Step 2: Check worker process is running**

```smalltalk
Process allInstances select: [ :p | p name = 'AgenticBrowser package watcher' ]
```

Expected: one process found.

- [ ] **Step 3: Close browser**

```smalltalk
AbBrowserPresenter allInstances do: [ :e | e window close ]
```
