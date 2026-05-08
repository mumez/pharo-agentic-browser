# Goal Setting Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a goal-setting feature to AgenticBrowser that lets users define a completion condition for a topic so the AI agent works autonomously until the goal is achieved.

**Architecture:** A new `AbTopicGoal` class holds all goal-related state (description, result text, callback block) and manages the result file path via a back-reference to the topic. `AbTopic` gains one instVar (`topicGoal`) and delegates goal logic to it. The state machine gains a `#goalAchieved` state that fires when `result-<topicId>.md` appears in the working directory after `end_turn`. Goal entry is via "Set Goal..." in the topic list context menu.

**Tech Stack:** Pharo 13, Spec 2 (SpPresenter), SsStateMachine, Tonel file format.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/AgenticBrowser-Core/AbTopicGoal.class.st` | Create | Goal state: description, achieved text, callback block, result file |
| `src/AgenticBrowser-Core/AbTopicGoalAchieved.class.st` | Create | Announcement class for goal achievement event |
| `src/AgenticBrowser-Core/AbTopic.class.st` | Modify | Add `topicGoal` instVar, `goal:`, `checkGoalAchievement`, `resetFromGoalAchieved`, `#goalAchieved` state |
| `src/AgenticBrowser-UI/AbTopicListPresenter.class.st` | Modify | Add "Set Goal..." context menu item and `onSetGoalRequest` handler |
| `src/AgenticBrowser-Tests/AbTopicGoalTest.class.st` | Create | Unit tests for AbTopicGoal |
| `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st` | Create | State machine tests for #goalAchieved transitions |

---

## Task 1: AbTopicGoalAchieved announcement class

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicGoalAchieved.class.st`

- [ ] **Step 1: Write the failing test**

In `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st`, create the test class and first test:

```smalltalk
Class {
	#name : 'AbTopicGoalStateTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedAnnouncementCarriesTopicAndGoal [

	| ann topic goal |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	ann := AbTopicGoalAchieved new topic: topic; goal: goal; yourself.
	self assert: ann topic == topic.
	self assert: ann goal == goal
]
```

- [ ] **Step 2: Import the test file into Pharo and run it to verify FAIL**

```
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalStateTest
```
Expected: Error — `AbTopicGoalAchieved` and `AbTopicGoal` do not exist.

- [ ] **Step 3: Create AbTopicGoalAchieved**

Create `src/AgenticBrowser-Core/AbTopicGoalAchieved.class.st`:

```smalltalk
Class {
	#name : 'AbTopicGoalAchieved',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'goal'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicGoalAchieved >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> goal [
	^ goal
]

{ #category : 'accessing' }
AbTopicGoalAchieved >> goal: anAbTopicGoal [
	goal := anAbTopicGoal
]
```

- [ ] **Step 4: Import core and run test — should still fail (AbTopicGoal missing)**

```
mcp: import_package AgenticBrowser-Core
mcp: run_class_test AbTopicGoalStateTest
```
Expected: Error — `AbTopicGoal` does not exist yet.

---

## Task 2: AbTopicGoal class

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicGoal.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicGoalTest.class.st`

- [ ] **Step 1: Write the failing tests**

Create `src/AgenticBrowser-Tests/AbTopicGoalTest.class.st`:

```smalltalk
Class {
	#name : 'AbTopicGoalTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicGoalTest >> testOnTopicCreatesInstance [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self assert: (goal isKindOf: AbTopicGoal)
]

{ #category : 'tests' }
AbTopicGoalTest >> testDescriptionAccessor [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: goal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalTest >> testIsAchievedFalseByDefault [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self deny: goal isAchieved
]

{ #category : 'tests' }
AbTopicGoalTest >> testResultFileIsInWorkingDirectory [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	self assert: goal resultFile parent = topic workingDirectory path.
	self assert: goal resultFile basename equals: 'result-' , topic topicId , '.md'
]

{ #category : 'tests' }
AbTopicGoalTest >> testNotificationPromptContainsDescriptionAndFileName [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self assert: (goal notificationPrompt includesSubstring: 'all tests pass').
	self assert: (goal notificationPrompt includesSubstring: 'result-' , topic topicId , '.md')
]

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsFalseWhenNoFile [

	| goal topic |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	self deny: goal checkAchievement
]

{ #category : 'tests' }
AbTopicGoalTest >> testCheckAchievementReturnsTrueAndSetsAchievedAndDeletesFile [

	| goal topic resultFile |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'all tests pass'.
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Goal reached: tests green.' ].
	[
		self assert: goal checkAchievement.
		self assert: goal isAchieved.
		self assert: goal achieved equals: 'Goal reached: tests green.'.
		self deny: resultFile exists ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]
```

- [ ] **Step 2: Import tests and run — verify FAIL**

```
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalTest
```
Expected: Error — `AbTopicGoal` does not exist.

- [ ] **Step 3: Create AbTopicGoal**

Create `src/AgenticBrowser-Core/AbTopicGoal.class.st`:

```smalltalk
Class {
	#name : 'AbTopicGoal',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'description',
		'achieved',
		'whenAchievedBlock'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicGoal class >> on: aTopic [

	^ self new topic: aTopic; yourself
]

{ #category : 'accessing' }
AbTopicGoal >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoal >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicGoal >> description [
	^ description
]

{ #category : 'accessing' }
AbTopicGoal >> description: aString [
	description := aString
]

{ #category : 'accessing' }
AbTopicGoal >> achieved [
	^ achieved
]

{ #category : 'testing' }
AbTopicGoal >> isAchieved [
	^ achieved notNil
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchieved: aBlock [
	whenAchievedBlock := aBlock
]

{ #category : 'accessing' }
AbTopicGoal >> resultFile [

	^ topic workingDirectory path / ('result-' , topic topicId , '.md')
]

{ #category : 'accessing' }
AbTopicGoal >> notificationPrompt [

	^ 'Goal has been set: ' , description
		, '. When the goal is achieved, summarize and report in result-'
		, topic topicId , '.md. Keep retrying until the goal is achieved.'
]

{ #category : 'operations' }
AbTopicGoal >> checkAchievement [

	| file |
	file := self resultFile.
	file exists ifFalse: [ ^ false ].
	achieved := file contents.
	file delete.
	^ true
]

{ #category : 'operations' }
AbTopicGoal >> runWhenAchievedBlock [

	whenAchievedBlock ifNotNil: [ whenAchievedBlock value ]
]
```

- [ ] **Step 4: Import and run tests**

```
mcp: import_package AgenticBrowser-Core
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalTest
```
Expected: All `AbTopicGoalTest` tests PASS. `AbTopicGoalStateTest` still fails (AbTopicGoal exists now but state tests need AbTopic changes).

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicGoal.class.st \
        src/AgenticBrowser-Core/AbTopicGoalAchieved.class.st \
        src/AgenticBrowser-Tests/AbTopicGoalTest.class.st \
        src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st
git commit -m "feat: add AbTopicGoal and AbTopicGoalAchieved classes with tests

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3: Add `#goalAchieved` state to AbTopic state machine

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st`

- [ ] **Step 1: Add state machine tests**

Append to `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedTransitionFromWorking [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic status equals: #goalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testResetFromGoalAchievedTransitionsToInitial [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	topic resetFromGoalAchieved.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testIsGoalAchievedPredicate [

	| topic |
	topic := AbTopic new.
	self deny: topic isGoalAchieved.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #goalReached.
	self assert: topic isGoalAchieved
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalAchievedStatusAnnouncementFired [

	| topic announced |
	topic := AbTopic new.
	announced := false.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | ann status = #goalAchieved ifTrue: [ announced := true ] ]
		for: self.
	[
		topic stateMachine handleEvent: #promptSent.
		topic stateMachine handleEvent: #goalReached.
		self assert: announced ]
	ensure: [ topic announcer unsubscribe: self ]
]
```

- [ ] **Step 2: Import tests and run — verify FAIL**

```
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalStateTest
```
Expected: FAIL — `#goalReached` event unknown, `isGoalAchieved` undefined.

- [ ] **Step 3: Modify AbTopic — add instVar, state machine state, and predicates**

In `src/AgenticBrowser-Core/AbTopic.class.st`:

Add `topicGoal` to instVars list:
```smalltalk
Class {
	#name : 'AbTopic',
	#superclass : 'Object',
	#instVars : [
		'title',
		'agentArguments',
		'messages',
		'client',
		'sessionId',
		'stateMachine',
		'announcer',
		'topicId',
		'packagePrefixes',
		'updatedExternalPackageNames',
		'workingDirectory',
		'relatedPackagesWatcher',
		'workingDirectoryPath',
		'logger',
		'availableCommands',
		'topicGoal'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}
```

Extend `initializeStateMachine` to add `#goalAchieved` state:
```smalltalk
{ #category : 'initialization' }
AbTopic >> initializeStateMachine [

	stateMachine := SsStateMachine new.
	(stateMachine addStateNamed: #initial)
		when: #permissionRequested to: #waitingForHuman;
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #working)
		entryAction: [ self announceStatusChanged: #working ];
		when: #permissionRequested to: #waitingForHuman;
		when: #turnEnded to: #endTurn;
		when: #goalReached to: #goalAchieved.
	(stateMachine addStateNamed: #waitingForHuman)
		entryAction: [ self announceStatusChanged: #waitingForHuman ];
		when: #humanResponded to: #working.
	(stateMachine addStateNamed: #endTurn)
		entryAction: [ self announceStatusChanged: #endTurn ];
		when: #permissionRequested to: #waitingForHuman;
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #goalAchieved)
		entryAction: [ self announceStatusChanged: #goalAchieved ];
		when: #reset to: #initial.
	stateMachine setStartStateTo: #initial.
	stateMachine start
]
```

Add testing and accessor methods:
```smalltalk
{ #category : 'testing' }
AbTopic >> isGoalAchieved [

	^ self status = #goalAchieved
]

{ #category : 'accessing' }
AbTopic >> topicGoal [
	^ topicGoal
]

{ #category : 'accessing' }
AbTopic >> topicGoal: anAbTopicGoal [
	topicGoal := anAbTopicGoal
]

{ #category : 'operations' }
AbTopic >> resetFromGoalAchieved [

	stateMachine handleEvent: #reset
]
```

- [ ] **Step 4: Import and run tests**

```
mcp: import_package AgenticBrowser-Core
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalStateTest
```
Expected: All state machine tests PASS. Also run existing tests to check no regression:
```
mcp: run_class_test AbTopicTest
```
Expected: All existing tests still PASS.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st
git commit -m "feat: add #goalAchieved state to AbTopic state machine

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4: Implement `goal:` on AbTopic and goal achievement check in `sendPrompt:`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st`

- [ ] **Step 1: Write the failing tests**

Append to `src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicGoalStateTest >> testGoalSetterCreatesAbTopicGoal [

	| topic |
	topic := AbTopic new.
	topic goal: 'all tests pass'.
	self assert: (topic topicGoal isKindOf: AbTopicGoal).
	self assert: topic topicGoal description equals: 'all tests pass'
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenNoGoal [

	| topic |
	topic := AbTopic new.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementReturnsFalseWhenFileAbsent [

	| topic |
	topic := AbTopic new.
	topic goal: 'all tests pass'.
	self deny: topic checkGoalAchievement
]

{ #category : 'tests' }
AbTopicGoalStateTest >> testCheckGoalAchievementTransitionsToGoalAchievedWhenFilePresent [

	| topic resultFile |
	topic := AbTopic new.
	topic goal: 'all tests pass'.
	topic stateMachine handleEvent: #promptSent.
	resultFile := topic topicGoal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Done.' ].
	[
		self assert: topic checkGoalAchievement.
		self assert: topic isGoalAchieved.
		self deny: resultFile exists ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]
```

- [ ] **Step 2: Import tests and run — verify FAIL**

```
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalStateTest
```
Expected: FAIL — `goal:` and `checkGoalAchievement` undefined on AbTopic.

- [ ] **Step 3: Add `goal:` and `checkGoalAchievement` to AbTopic**

Add to `src/AgenticBrowser-Core/AbTopic.class.st`:

```smalltalk
{ #category : 'operations' }
AbTopic >> goal: aString [

	topicGoal := AbTopicGoal on: self.
	topicGoal description: aString.
	self sendPrompt: topicGoal notificationPrompt
]

{ #category : 'operations' }
AbTopic >> checkGoalAchievement [

	topicGoal ifNil: [ ^ false ].
	(topicGoal checkAchievement) ifFalse: [ ^ false ].
	stateMachine handleEvent: #goalReached.
	self announceGoalAchieved.
	topicGoal runWhenAchievedBlock.
	^ true
]

{ #category : 'private' }
AbTopic >> announceGoalAchieved [

	self announcer announce: (AbTopicGoalAchieved new
			 topic: self;
			 goal: topicGoal;
			 yourself)
]
```

Modify `sendPrompt:` to call `checkGoalAchievement` before firing `#turnEnded`:

```smalltalk
{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	| msg |
	msg := AbMessage sender: #human text: aString.
	messages add: msg.
	self announceMessageAdded: msg.
	stateMachine handleEvent: #promptSent.
	[
	| result |
	self ensureConnected.
		result := client promptBy: [ :params |
				  params sessionId: sessionId.
				  params textPrompt: aString ].
		result stopReason = 'end_turn' ifTrue: [
			self checkGoalAchievement ifFalse: [
				stateMachine handleEvent: #turnEnded ] ] ] fork
]
```

- [ ] **Step 4: Import and run tests**

```
mcp: import_package AgenticBrowser-Core
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalStateTest
mcp: run_class_test AbTopicTest
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Tests/AbTopicGoalStateTest.class.st
git commit -m "feat: implement goal: setter and checkGoalAchievement on AbTopic

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5: `whenGoalAchieved:` default announcement + iconNameFor: in UI

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicGoal.class.st` (default block)
- Modify: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st` (icon for `#goalAchieved`)
- Test: `src/AgenticBrowser-Tests/AbTopicGoalTest.class.st`

- [ ] **Step 1: Write the failing test**

Append to `src/AgenticBrowser-Tests/AbTopicGoalTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicGoalTest >> testWhenAchievedBlockIsCalledAfterCheckAchievement [

	| goal topic resultFile called |
	topic := AbTopic new.
	goal := AbTopicGoal on: topic.
	goal description: 'done'.
	called := false.
	goal whenAchieved: [ called := true ].
	resultFile := goal resultFile.
	resultFile parent ensureCreateDirectory.
	resultFile writeStreamDo: [ :s | s nextPutAll: 'Result.' ].
	[
		goal checkAchievement.
		goal runWhenAchievedBlock.
		self assert: called ]
	ensure: [
		resultFile exists ifTrue: [ resultFile delete ] ]
]
```

- [ ] **Step 2: Import and run — verify PASS (already implemented in Task 2)**

```
mcp: import_package AgenticBrowser-Tests
mcp: run_class_test AbTopicGoalTest
```
Expected: PASS (runWhenAchievedBlock already exists).

- [ ] **Step 3: Add `#goalAchieved` icon to AbTopicListPresenter**

In `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`, modify `iconNameFor:`:

```smalltalk
{ #category : 'private' }
AbTopicListPresenter >> iconNameFor: aTopic [

	aTopic isInitial ifTrue: [ ^ #radioButtonOff ].
	aTopic isWorking ifTrue: [ ^ #pointersTo ].
	aTopic isWaitingForHuman ifTrue: [ ^ #flag ].
	aTopic isGoalAchieved ifTrue: [ ^ #glamorousCheckboxSelected ].
	aTopic isEndTurn ifTrue: [ ^ #accept ].
	^ #radioButtonOff
]
```

- [ ] **Step 4: Import and run full test suite**

```
mcp: import_package AgenticBrowser-UI
mcp: run_package_test AgenticBrowser-Tests
```
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbTopicListPresenter.class.st \
        src/AgenticBrowser-Tests/AbTopicGoalTest.class.st
git commit -m "feat: add goalAchieved icon and whenAchieved block test

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 6: "Set Goal..." context menu in AbTopicListPresenter

**Files:**
- Modify: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`

- [ ] **Step 1: Check existing test class**

Read `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st` to understand the existing test patterns before adding tests.

- [ ] **Step 2: Add "Set Goal..." to context menu and handler**

In `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`:

Add to `buildTopicContextMenu`:
```smalltalk
{ #category : 'private' }
AbTopicListPresenter >> buildTopicContextMenu [

	^ SpMenuPresenter new
		  addItem: [ :item | item name: 'Inspect...'; action: [ self onInspectTopicRequest ] ];
		  addItem: [ :item | item name: 'Set Goal...'; action: [ self onSetGoalRequest ] ];
		  addItem: [ :item | item name: 'Set Target Packages...'; action: [ self onSetTargetPackagesRequest ] ];
		  addItem: [ :item | item name: 'Apply Updated External Packages'; action: [ self onApplyUpdatedExternalPackagesRequest ] ];
		  addItem: [ :item | item name: 'Set Working Directory...'; action: [ self onSetWorkingDirectoryRequest ] ];
		  addItem: [ :item | item name: 'Set Agent...'; action: [ self onSetAgentRequest ] ];
		  addItem: [ :item | item name: 'Rename...'; action: [ self onRenameTopicRequest ] ];
		  addItem: [ :item | item name: 'Delete'; action: [ self onDeleteTopicRequest ] ];
		  yourself
]
```

Add `onSetGoalRequest` handler:
```smalltalk
{ #category : 'private' }
AbTopicListPresenter >> onSetGoalRequest [

	| topic goalText |
	topic := self topicList selectedItem.
	topic ifNil: [ ^ self ].
	goalText := UIManager default
		request: 'Goal (completion condition):'
		initialAnswer: (topic topicGoal ifNotNil: [ :g | g description ] ifNil: [ '' ])
		title: 'Set Goal'.
	(goalText isNil or: [ goalText trimmed isEmpty ]) ifTrue: [ ^ self ].
	topic goal: goalText trimmed
]
```

- [ ] **Step 3: Import and run all tests**

```
mcp: import_package AgenticBrowser-UI
mcp: run_package_test AgenticBrowser-Tests
```
Expected: All tests PASS.

- [ ] **Step 4: Lint check**

```
mcp: lint_tonel_smalltalk_from_file src/AgenticBrowser-UI/AbTopicListPresenter.class.st
mcp: lint_tonel_smalltalk_from_file src/AgenticBrowser-Core/AbTopic.class.st
mcp: lint_tonel_smalltalk_from_file src/AgenticBrowser-Core/AbTopicGoal.class.st
```

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbTopicListPresenter.class.st
git commit -m "feat: add 'Set Goal...' context menu to topic list

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Self-Review

### Spec coverage vs. requirements

| Requirement | Task |
|-------------|------|
| `goal:` sets goal and sends notification prompt | Task 4 |
| Notification prompt text includes description and result filename | Task 2 (notificationPrompt) |
| `result-<topicId>.md` detection after end_turn | Task 4 (checkGoalAchievement + sendPrompt:) |
| File read, delete, store in `achieved` | Task 2 (AbTopicGoal checkAchievement) |
| `#goalAchieved` state with announcement | Task 3 |
| `#goalAchieved` → `#initial` via reset only | Task 3 |
| `whenGoalAchieved: aBlock` optional callback | Task 2, Task 5 |
| Default fires `AbTopicGoalAchieved` announcement | Task 4 (announceGoalAchieved) |
| UI: right-click "Set Goal..." in topic list | Task 6 |
| Icon for `#goalAchieved` status | Task 5 |

### Placeholder scan
No TBDs or "similar to Task N" references found. All code blocks are complete.

### Type consistency
- `AbTopicGoal on: topic` used in Task 2 (class side), Task 4 (`goal:` method) — consistent.
- `topicGoal` instVar name consistent across Task 3 (instVars, accessor) and Task 4 (goal:, checkGoalAchievement).
- `AbTopicGoalAchieved` carrying `topic` + `goal` fields consistent between Task 1 (class) and Task 4 (`announceGoalAchieved`).
- `stateMachine handleEvent: #goalReached` in Task 3 (state definition) and Task 4 (checkGoalAchievement) — consistent.
