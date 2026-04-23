# pharo-agentic-browser Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Pharo GUI application for managing multiple AI agent work sessions as topics, using pharo-acp (ACP client) as backend and SState for topic state management.

**Architecture:** Three packages: AgenticBrowser-Core (domain model with AbTopic/AbTopicManager/AbMessage and announcements), AgenticBrowser-Handler (AbTopicHandler bridges pharo-acp callbacks to domain), AgenticBrowser-UI (Spec2 presenters for 2-pane browser). Topics use SState FSM for status tracking. Human-in-the-loop approval uses Semaphore to block the handler thread while the UI collects user text response.

**Tech Stack:** Pharo 12+, Spec2 (built-in), pharo-acp (`github://mumez/pharo-acp:main/src`), SState (`github://mumez/SState/src`), Tonel source format

---

## File Map

```
src/
  BaselineOfAgenticBrowser/
    package.st
    BaselineOfAgenticBrowser.class.st

  AgenticBrowser-Core/
    package.st
    AbMessage.class.st
    AbTopicStatusChanged.class.st
    AbMessageAdded.class.st
    AbTopic.class.st
    AbTopicManager.class.st

  AgenticBrowser-Handler/
    package.st
    AbTopicHandler.class.st

  AgenticBrowser-UI/
    package.st
    AbBrowserPresenter.class.st
    AbTopicListPresenter.class.st
    AbChatPresenter.class.st
    AbNewTopicDialog.class.st

  AgenticBrowser-Tests/
    package.st
    AbMessageTest.class.st
    AbTopicTest.class.st
    AbTopicManagerTest.class.st
```

---

## Development workflow (Smalltalk-specific)

All source lives as Tonel files in `src/`. The edit→import→test cycle:

1. Write/edit Tonel files in `src/`
2. Lint: use `/st-lint` skill or `mcp__plugin_smalltalk-dev_smalltalk-validator__lint_tonel_smalltalk_from_file`
3. Import: use `/st-import` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__import_package`
4. Run tests: use `/st-test` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test`
5. After interactive fixes in image, export back: use `/st-export` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__export_package`

Import command reference:
```smalltalk
"Load from local src/ — run in Pharo Playground"
Metacello new
    baseline: 'AgenticBrowser';
    repository: 'tonel:///home/mumez/git/pharo-agentic-browser/src';
    load: 'Tests'.
```

---

## Task 1: Baseline + directory scaffold

**Files:**
- Create: `src/BaselineOfAgenticBrowser/package.st`
- Create: `src/BaselineOfAgenticBrowser/BaselineOfAgenticBrowser.class.st`
- Create: `src/AgenticBrowser-Core/package.st`
- Create: `src/AgenticBrowser-Handler/package.st`
- Create: `src/AgenticBrowser-UI/package.st`
- Create: `src/AgenticBrowser-Tests/package.st`

- [ ] **Step 1: Create package.st files**

`src/BaselineOfAgenticBrowser/package.st`:
```
Package { #name : 'BaselineOfAgenticBrowser' }
```

`src/AgenticBrowser-Core/package.st`:
```
Package { #name : 'AgenticBrowser-Core' }
```

`src/AgenticBrowser-Handler/package.st`:
```
Package { #name : 'AgenticBrowser-Handler' }
```

`src/AgenticBrowser-UI/package.st`:
```
Package { #name : 'AgenticBrowser-UI' }
```

`src/AgenticBrowser-Tests/package.st`:
```
Package { #name : 'AgenticBrowser-Tests' }
```

- [ ] **Step 2: Write BaselineOfAgenticBrowser.class.st**

`src/BaselineOfAgenticBrowser/BaselineOfAgenticBrowser.class.st`:
```
Class {
	#name : 'BaselineOfAgenticBrowser',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfAgenticBrowser',
	#package : 'BaselineOfAgenticBrowser'
}

{ #category : 'baselines' }
BaselineOfAgenticBrowser >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			baseline: 'ACP'
			with: [ spec repository: 'github://mumez/pharo-acp:main/src' ].
		spec
			baseline: 'SState'
			with: [ spec repository: 'github://mumez/SState/src' ].
		spec
			package: 'AgenticBrowser-Core'
			with: [ spec requires: #( 'ACP' 'SState' ) ].
		spec
			package: 'AgenticBrowser-Handler'
			with: [ spec requires: #( 'AgenticBrowser-Core' 'ACP' ) ].
		spec
			package: 'AgenticBrowser-UI'
			with: [ spec requires: #( 'AgenticBrowser-Handler' ) ].
		spec
			package: 'AgenticBrowser-Tests'
			with: [ spec requires: #( 'AgenticBrowser-Core' 'AgenticBrowser-Handler' ) ].
		spec
			group: 'default'
			with: #( 'AgenticBrowser-Core' 'AgenticBrowser-Handler' 'AgenticBrowser-UI' ).
		spec
			group: 'Tests'
			with: #( 'default' 'AgenticBrowser-Tests' ) ]
]
```

- [ ] **Step 3: Commit scaffold**

```bash
git add src/
git commit -m "Add project scaffold: package structure and Metacello baseline"
```

---

## Task 2: AbMessage + tests

**Files:**
- Create: `src/AgenticBrowser-Core/AbMessage.class.st`
- Create: `src/AgenticBrowser-Tests/AbMessageTest.class.st`

- [ ] **Step 1: Write AbMessageTest.class.st**

`src/AgenticBrowser-Tests/AbMessageTest.class.st`:
```
Class {
	#name : 'AbMessageTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbMessageTest >> testHumanMessageCreation [

	| msg |
	msg := AbMessage sender: #human text: 'Fix the N+1 issue'.
	self assert: msg sender equals: #human.
	self assert: msg text equals: 'Fix the N+1 issue'.
	self deny: msg isApprovalRequest.
	self assert: msg approvalSemaphore isNil
]

{ #category : 'tests' }
AbMessageTest >> testAiMessageCreation [

	| msg |
	msg := AbMessage sender: #ai text: 'Working on it'.
	self assert: msg sender equals: #ai.
	self assert: msg timestamp notNil
]

{ #category : 'tests' }
AbMessageTest >> testApprovalRequestCreation [

	| msg |
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	self assert: msg sender equals: #ai.
	self assert: msg text equals: 'May I modify DBAdapter?'.
	self assert: msg isApprovalRequest.
	self assert: msg approvalSemaphore notNil.
	self assert: msg approvalResponse isNil
]

{ #category : 'tests' }
AbMessageTest >> testAppendText [

	| msg |
	msg := AbMessage sender: #ai text: 'Starting '.
	msg appendText: 'work...'.
	self assert: msg text equals: 'Starting work...'
]

{ #category : 'tests' }
AbMessageTest >> testDisplayStringHuman [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	self assert: (msg displayText includesSubstring: 'Human')
]

{ #category : 'tests' }
AbMessageTest >> testDisplayStringAi [

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	self assert: (msg displayText includesSubstring: 'AI')
]
```

- [ ] **Step 2: Write AbMessage.class.st**

`src/AgenticBrowser-Core/AbMessage.class.st`:
```
Class {
	#name : 'AbMessage',
	#superclass : 'Object',
	#instVars : [
		'sender',
		'text',
		'timestamp',
		'isApprovalRequest',
		'approvalSemaphore',
		'approvalResponse'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbMessage class >> sender: aSenderSymbol text: aString [

	^ self new
		  sender: aSenderSymbol;
		  text: aString;
		  yourself
]

{ #category : 'instance creation' }
AbMessage class >> approvalRequestText: aString [

	^ self new
		  sender: #ai;
		  text: aString;
		  isApprovalRequest: true;
		  approvalSemaphore: Semaphore new;
		  yourself
]

{ #category : 'initialization' }
AbMessage >> initialize [

	sender := #system.
	text := ''.
	timestamp := DateAndTime now.
	isApprovalRequest := false
]

{ #category : 'accessing' }
AbMessage >> sender [
	^ sender
]

{ #category : 'accessing' }
AbMessage >> sender: aSymbol [
	sender := aSymbol
]

{ #category : 'accessing' }
AbMessage >> text [
	^ text
]

{ #category : 'accessing' }
AbMessage >> text: aString [
	text := aString
]

{ #category : 'accessing' }
AbMessage >> timestamp [
	^ timestamp
]

{ #category : 'accessing' }
AbMessage >> isApprovalRequest [
	^ isApprovalRequest
]

{ #category : 'accessing' }
AbMessage >> isApprovalRequest: aBoolean [
	isApprovalRequest := aBoolean
]

{ #category : 'accessing' }
AbMessage >> approvalSemaphore [
	^ approvalSemaphore
]

{ #category : 'accessing' }
AbMessage >> approvalSemaphore: aSemaphore [
	approvalSemaphore := aSemaphore
]

{ #category : 'accessing' }
AbMessage >> approvalResponse [
	^ approvalResponse
]

{ #category : 'accessing' }
AbMessage >> approvalResponse: aSymbol [
	approvalResponse := aSymbol
]

{ #category : 'operations' }
AbMessage >> appendText: aString [
	text := text , aString
]

{ #category : 'displaying' }
AbMessage >> displayText [
	"Returns a formatted string for display in the chat pane."
	| prefix |
	prefix := sender = #human
		ifTrue: [ '[Human] ' ]
		ifFalse: [ sender = #ai
			ifTrue: [ isApprovalRequest ifTrue: [ '[⏸ AI] ' ] ifFalse: [ '[AI] ' ] ]
			ifFalse: [ '[System] ' ] ].
	^ prefix , text
]
```

- [ ] **Step 3: Import and run tests**

Import: `/st-import AgenticBrowser-Tests` (also loads AgenticBrowser-Core as dependency)

Run tests:
```
/st-test AbMessageTest
```
Expected: 6 tests pass.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-Core/AbMessage.class.st src/AgenticBrowser-Tests/AbMessageTest.class.st
git commit -m "Add AbMessage domain object with tests"
```

---

## Task 3: Announcements

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicStatusChanged.class.st`
- Create: `src/AgenticBrowser-Core/AbMessageAdded.class.st`

- [ ] **Step 1: Write AbTopicStatusChanged.class.st**

`src/AgenticBrowser-Core/AbTopicStatusChanged.class.st`:
```
Class {
	#name : 'AbTopicStatusChanged',
	#superclass : 'Announcement',
	#instVars : [ 'topic' ],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicStatusChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicStatusChanged >> topic: anAbTopic [
	topic := anAbTopic
]
```

- [ ] **Step 2: Write AbMessageAdded.class.st**

`src/AgenticBrowser-Core/AbMessageAdded.class.st`:
```
Class {
	#name : 'AbMessageAdded',
	#superclass : 'Announcement',
	#instVars : [ 'topic', 'message' ],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbMessageAdded >> topic [
	^ topic
]

{ #category : 'accessing' }
AbMessageAdded >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbMessageAdded >> message [
	^ message
]

{ #category : 'accessing' }
AbMessageAdded >> message: anAbMessage [
	message := anAbMessage
]
```

- [ ] **Step 3: Import and commit**

Import: `/st-import AgenticBrowser-Core`

```bash
git add src/AgenticBrowser-Core/AbTopicStatusChanged.class.st src/AgenticBrowser-Core/AbMessageAdded.class.st
git commit -m "Add AbTopicStatusChanged and AbMessageAdded announcements"
```

---

## Task 4: AbTopic + tests

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopic.class.st`
- Create: `src/AgenticBrowser-Tests/AbTopicTest.class.st`

- [ ] **Step 1: Write AbTopicTest.class.st**

`src/AgenticBrowser-Tests/AbTopicTest.class.st`:
```
Class {
	#name : 'AbTopicTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicTest >> testInitialStatus [

	self assert: AbTopic new status equals: #idle
]

{ #category : 'tests' }
AbTopicTest >> testPromptSentTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testHumanRespondedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	topic stateMachine handleEvent: #humanResponded.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testEndedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #ended.
	self assert: topic status equals: #done
]

{ #category : 'tests' }
AbTopicTest >> testDoneToWorkingOnNewPrompt [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #ended.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalAllowAlways [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	topic messages add: msg.
	topic resolveApproval: 'yes'.
	self assert: msg approvalResponse equals: #allowAlways.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalRejectOnce [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I delete files?'.
	topic messages add: msg.
	topic resolveApproval: 'no'.
	self assert: msg approvalResponse equals: #rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkCreatesMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Hello'
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkAppendsToExistingAiMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	topic addAiTextChunk: ' world'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last text equals: 'Hello world'
]

{ #category : 'tests' }
AbTopicTest >> testAddApprovalRequestAddsMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addApprovalRequest: 'May I delete files?'.
	self assert: topic messages size equals: 1.
	self assert: msg isApprovalRequest.
	self assert: msg approvalSemaphore notNil
]

{ #category : 'tests' }
AbTopicTest >> testStatusChangedAnnouncementFired [

	| topic statusChanges |
	topic := AbTopic new.
	statusChanges := OrderedCollection new.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | statusChanges add: ann topic status ].
	topic stateMachine handleEvent: #promptSent.
	self assert: (statusChanges includes: #working)
]
```

- [ ] **Step 2: Write AbTopic.class.st**

`src/AgenticBrowser-Core/AbTopic.class.st`:
```
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
		'watchedPackages'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'initialization' }
AbTopic >> initialize [

	title := 'Untitled'.
	agentArguments := #( 'claude-agent-acp' ).
	messages := OrderedCollection new.
	watchedPackages := OrderedCollection new.
	self initializeStateMachine
]

{ #category : 'initialization' }
AbTopic >> initializeStateMachine [

	stateMachine := SsStateMachine new.
	(stateMachine addStateNamed: #idle)
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #working)
		entryAction: [ self announceStatusChanged ];
		when: #permissionRequested to: #waitingForHuman;
		when: #ended to: #done.
	(stateMachine addStateNamed: #waitingForHuman)
		entryAction: [ self announceStatusChanged ];
		when: #humanResponded to: #working.
	(stateMachine addStateNamed: #done)
		entryAction: [ self announceStatusChanged ];
		when: #promptSent to: #working.
	stateMachine setStartStateTo: #idle.
	stateMachine start
]

{ #category : 'accessing' }
AbTopic >> title [
	^ title
]

{ #category : 'accessing' }
AbTopic >> title: aString [
	title := aString
]

{ #category : 'accessing' }
AbTopic >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbTopic >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> client [
	^ client
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
AbTopic >> stateMachine [
	^ stateMachine
]

{ #category : 'accessing' }
AbTopic >> watchedPackages [
	^ watchedPackages
]

{ #category : 'accessing' }
AbTopic >> status [
	^ stateMachine currentState name
]

{ #category : 'accessing' }
AbTopic >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	| msg |
	msg := AbMessage sender: #human text: aString.
	messages add: msg.
	self announceMessageAdded: msg.
	stateMachine handleEvent: #promptSent.
	[
	self ensureConnected.
	| result |
	result := client promptBy: [ :params |
		          params sessionId: sessionId.
		          params textPrompt: aString ].
	result stopReason = 'end_turn' ifTrue: [
		stateMachine handleEvent: #ended ] ] fork
]

{ #category : 'operations' }
AbTopic >> addAiTextChunk: aString [

	| msg |
	(messages notEmpty and: [
		 messages last sender = #ai and: [ messages last isApprovalRequest not ] ])
		ifTrue: [ messages last appendText: aString ]
		ifFalse: [
			msg := AbMessage sender: #ai text: aString.
			messages add: msg ].
	self announceMessageAdded: messages last
]

{ #category : 'operations' }
AbTopic >> addApprovalRequest: aDescription [

	| msg |
	msg := AbMessage approvalRequestText: aDescription.
	messages add: msg.
	self announceMessageAdded: msg.
	^ msg
]

{ #category : 'operations' }
AbTopic >> resolveApproval: aUserText [

	| pending response |
	pending := messages
		           detect: [ :m |
			           m isApprovalRequest and: [ m approvalResponse isNil ] ]
		           ifNone: [ ^ self ].
	response := (aUserText trimSeparators asLowercase includesSubstring: 'no') |
	            (aUserText trimSeparators asLowercase includesSubstring: 'deny') |
	            (aUserText trimSeparators asLowercase includesSubstring: 'reject')
		            ifTrue: [ #rejectOnce ]
		            ifFalse: [ #allowAlways ].
	pending approvalResponse: response.
	stateMachine handleEvent: #humanResponded.
	pending approvalSemaphore signal
]

{ #category : 'operations' }
AbTopic >> disconnect [

	client ifNotNil: [
		client disconnect.
		client := nil.
		sessionId := nil ]
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	client isNil ifTrue: [ self doConnect ]
]

{ #category : 'private' }
AbTopic >> doConnect [

	| sessionResult |
	client := ACPClient new.
	client handler: (AbTopicHandler new topic: self; yourself).
	client agentCommand: '/usr/bin/env' arguments: agentArguments.
	client connect.
	client initializeBy: [ :params | "use defaults" ].
	sessionResult := client newSessionBy: [ :params |
		                 params cwd: FileSystem workingDirectory fullName ].
	sessionId := sessionResult sessionId
]

{ #category : 'private' }
AbTopic >> announceStatusChanged [

	self announcer announce:
		(AbTopicStatusChanged new topic: self; yourself)
]

{ #category : 'private' }
AbTopic >> announceMessageAdded: aMessage [

	self announcer announce: (AbMessageAdded new
		 topic: self;
		 message: aMessage;
		 yourself)
]
```

- [ ] **Step 3: Import and run tests**

Import: `/st-import AgenticBrowser-Tests`

Run: `/st-test AbTopicTest`

Expected: 12 tests pass. The state transition tests do not require an ACP connection.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
git commit -m "Add AbTopic with SState state machine and tests"
```

---

## Task 5: AbTopicManager + tests

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicManager.class.st`
- Create: `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`

- [ ] **Step 1: Write AbTopicManagerTest.class.st**

`src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`:
```
Class {
	#name : 'AbTopicManagerTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicManagerTest >> setUp [

	AbTopicManager resetInstance
]

{ #category : 'tests' }
AbTopicManagerTest >> testUniqueInstance [

	self assert: AbTopicManager uniqueInstance == AbTopicManager uniqueInstance
]

{ #category : 'tests' }
AbTopicManagerTest >> testAddTopic [

	| manager topic |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	self assert: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopic [

	| manager topic |
	manager := AbTopicManager uniqueInstance.
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	manager removeTopic: topic.
	self deny: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsInitiallyEmpty [

	self assert: AbTopicManager uniqueInstance topics isEmpty
]
```

- [ ] **Step 2: Write AbTopicManager.class.st**

`src/AgenticBrowser-Core/AbTopicManager.class.st`:
```
Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [ 'topics' ],
	#classInstVars : [ 'uniqueInstance' ],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManager class >> uniqueInstance [

	^ uniqueInstance ifNil: [ uniqueInstance := self new ]
]

{ #category : 'testing' }
AbTopicManager class >> resetInstance [

	uniqueInstance := nil
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := OrderedCollection new
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics add: anAbTopic
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	topics remove: anAbTopic ifAbsent: []
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics do: aBlock
]
```

- [ ] **Step 3: Import and run tests**

Import: `/st-import AgenticBrowser-Tests`

Run: `/st-test AbTopicManagerTest`

Expected: 4 tests pass.

- [ ] **Step 4: Run all domain tests together**

Run: `/st-test AgenticBrowser-Tests`

Expected: all tests pass (AbMessageTest + AbTopicTest + AbTopicManagerTest).

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicManager.class.st src/AgenticBrowser-Tests/AbTopicManagerTest.class.st
git commit -m "Add AbTopicManager singleton with tests"
```

---

## Task 6: AbTopicHandler

**Files:**
- Create: `src/AgenticBrowser-Handler/AbTopicHandler.class.st`

No automated tests for this class — it requires a live ACP connection. Integration is verified in Task 11.

- [ ] **Step 1: Write AbTopicHandler.class.st**

`src/AgenticBrowser-Handler/AbTopicHandler.class.st`:
```
Class {
	#name : 'AbTopicHandler',
	#superclass : 'ACPClientHandler',
	#instVars : [ 'topic' ],
	#category : 'AgenticBrowser-Handler',
	#package : 'AgenticBrowser-Handler'
}

{ #category : 'accessing' }
AbTopicHandler >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicHandler >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'agent-callbacks' }
AbTopicHandler >> sessionUpdate: aSessionUpdate [
	"Stream AI output chunks to the topic."

	(aSessionUpdate isAgentMessageChunk or: [ aSessionUpdate isAgentThoughtChunk ])
		ifFalse: [ ^ self ].
	topic addAiTextChunk: aSessionUpdate content text
]

{ #category : 'agent-callbacks' }
AbTopicHandler >> requestPermission: anACPRequestPermission [
	"Block this handler thread until the user responds via the chat UI."

	| msg response |
	msg := topic addApprovalRequest: anACPRequestPermission printString.
	topic stateMachine handleEvent: #permissionRequested.
	msg approvalSemaphore wait.
	response := anACPRequestPermission makeResponse.
	msg approvalResponse = #rejectOnce ifTrue: [
		response rejectOnce.
		^ response ].
	msg approvalResponse = #rejectAlways ifTrue: [
		response rejectAlways.
		^ response ].
	response allowAlways.
	^ response
]
```

- [ ] **Step 2: Import**

Import: `/st-import AgenticBrowser-Handler`

Verify no syntax errors by checking image transcript.

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-Handler/AbTopicHandler.class.st
git commit -m "Add AbTopicHandler bridging ACP callbacks to AbTopic"
```

---

## Task 7: AbBrowserPresenter

**Files:**
- Create: `src/AgenticBrowser-UI/AbBrowserPresenter.class.st`

- [ ] **Step 1: Write AbBrowserPresenter.class.st**

`src/AgenticBrowser-UI/AbBrowserPresenter.class.st`:
```
Class {
	#name : 'AbBrowserPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'topicListPresenter',
		'chatPresenter'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AbBrowserPresenter class >> open [

	^ self new open
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializePresenters [

	topicListPresenter := self instantiate: AbTopicListPresenter.
	chatPresenter := self instantiate: AbChatPresenter
]

{ #category : 'initialization' }
AbBrowserPresenter >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Agentic Browser';
		initialExtent: 900 @ 600.
	aWindowPresenter whenClosedDo: [ self onWindowClosed ]
]

{ #category : 'initialization' }
AbBrowserPresenter >> connectPresenters [

	topicListPresenter onTopicSelected: [ :topic |
		chatPresenter topic: topic ]
]

{ #category : 'layout' }
AbBrowserPresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  add: topicListPresenter withConstraints: [ :c | c width: 220 ];
		  add: chatPresenter;
		  yourself
]

{ #category : 'private' }
AbBrowserPresenter >> onWindowClosed [

	AbTopicManager uniqueInstance topicsDo: [ :t |
		[ t disconnect ] on: Error do: [ :e | "ignore disconnect errors" ] ]
]
```

- [ ] **Step 2: Import and verify**

Import: `/st-import AgenticBrowser-UI`

Open a Pharo Playground and evaluate:
```smalltalk
AbBrowserPresenter open.
```

Expected: a window opens with a left panel and right panel (both empty at this stage).

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbBrowserPresenter.class.st
git commit -m "Add AbBrowserPresenter main 2-pane window"
```

---

## Task 8: AbTopicListPresenter

**Files:**
- Create: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`

- [ ] **Step 1: Write AbTopicListPresenter.class.st**

`src/AgenticBrowser-UI/AbTopicListPresenter.class.st`:
```
Class {
	#name : 'AbTopicListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'topicList',
		'newTopicButton',
		'onTopicSelectedBlock'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbTopicListPresenter >> initializePresenters [

	topicList := self newList.
	topicList display: [ :topic | self statusIconFor: topic , ' ' , topic title ].
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'initialization' }
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	newTopicButton action: [ self onNewTopicRequest ].
	self subscribeToTopicManager
]

{ #category : 'layout' }
AbTopicListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: topicList;
		  add: newTopicButton
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'api' }
AbTopicListPresenter >> onTopicSelected: aBlock [

	onTopicSelectedBlock := aBlock
]

{ #category : 'api' }
AbTopicListPresenter >> refresh [

	| items |
	items := AbTopicManager uniqueInstance topics asArray.
	topicList items: items
]

{ #category : 'private' }
AbTopicListPresenter >> statusIconFor: aTopic [

	aTopic status = #working ifTrue: [ ^ '●' ].
	aTopic status = #waitingForHuman ifTrue: [ ^ '⏸' ].
	aTopic status = #done ifTrue: [ ^ '✓' ].
	^ '○'
]

{ #category : 'private' }
AbTopicListPresenter >> subscribeToTopicManager [

	"Subscribe to status changes on all current and future topics.
	 Refresh the list whenever any topic status changes."
	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer when: AbTopicStatusChanged do: [ self defer: [ self refresh ] ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		topic announcer
			when: AbTopicStatusChanged
			do: [ self defer: [ self refresh ] ].
		self refresh.
		topicList selectItem: topic ]
]
```

- [ ] **Step 2: Import and smoke-test**

Import: `/st-import AgenticBrowser-UI`

Open the browser window and verify:
- Topic list is empty initially
- "New Topic" button is visible

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbTopicListPresenter.class.st
git commit -m "Add AbTopicListPresenter with status icons and new topic button"
```

---

## Task 9: AbChatPresenter

**Files:**
- Create: `src/AgenticBrowser-UI/AbChatPresenter.class.st`

- [ ] **Step 1: Write AbChatPresenter.class.st**

`src/AgenticBrowser-UI/AbChatPresenter.class.st`:
```
Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageDisplay',
		'inputField',
		'sendButton',
		'currentTopic',
		'pendingApprovalMessage'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'
]

{ #category : 'initialization' }
AbChatPresenter >> connectPresenters [

	sendButton action: [ self onSendButtonClicked ]
]

{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageDisplay;
		  add: (SpBoxLayout newLeftToRight
				   add: inputField;
				   add: sendButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 60 ];
		  yourself
]

{ #category : 'api' }
AbChatPresenter >> topic: anAbTopic [

	currentTopic := anAbTopic.
	self unsubscribeCurrentTopic.
	self subscribeToTopic: anAbTopic.
	self rerenderMessages
]

{ #category : 'api' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	pendingApprovalMessage := anAbMessage.
	inputField placeholder: 'Respond to AI (yes / no / always)...'.
	inputField text: ''
]

{ #category : 'api' }
AbChatPresenter >> exitApprovalMode [

	pendingApprovalMessage := nil.
	inputField placeholder: 'Type your request...'
]

{ #category : 'private' }
AbChatPresenter >> onSendButtonClicked [

	| text |
	text := inputField text trim.
	text isEmpty ifTrue: [ ^ self ].
	inputField text: ''.
	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage
		ifNotNil: [ currentTopic resolveApproval: text ]
		ifNil: [ currentTopic sendPrompt: text ]
]

{ #category : 'private' }
AbChatPresenter >> subscribeToTopic: aTopic [

	aTopic announcer
		when: AbMessageAdded
		do: [ :ann | self defer: [ self onMessageAdded: ann message ] ].
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self defer: [ self onTopicStatusChanged: ann topic ] ]
]

{ #category : 'private' }
AbChatPresenter >> unsubscribeCurrentTopic [

	"Spec2 Announcer subscriptions are per-block; unsubscribe by replacing topic.
	 New subscriptions on topic: replace old ones implicitly since old topic is discarded."
]

{ #category : 'private' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self rerenderMessages.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'private' }
AbChatPresenter >> onTopicStatusChanged: aTopic [

	aTopic status = #working ifTrue: [ self exitApprovalMode ].
	self rerenderMessages
]

{ #category : 'private' }
AbChatPresenter >> rerenderMessages [

	currentTopic ifNil: [ ^ self ].
	messageDisplay text: (String streamContents: [ :s |
			 currentTopic messages do: [ :m |
				 s
					 nextPutAll: m displayText;
					 cr ] ])
]
```

- [ ] **Step 2: Import and smoke-test**

Import: `/st-import AgenticBrowser-UI`

Open the browser:
```smalltalk
AbBrowserPresenter open.
```

Add a topic via New Topic dialog and select it. Chat pane should show as empty and accept input.

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st
git commit -m "Add AbChatPresenter with streaming display and approval mode"
```

---

## Task 10: AbNewTopicDialog

**Files:**
- Create: `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`

- [ ] **Step 1: Write AbNewTopicDialog.class.st**

`src/AgenticBrowser-UI/AbNewTopicDialog.class.st`:
```
Class {
	#name : 'AbNewTopicDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleField',
		'agentDropList',
		'okButton',
		'cancelButton',
		'topic'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbNewTopicDialog >> initializePresenters [

	titleField := self newTextInput.
	titleField placeholder: 'Topic title...'.

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].

	okButton := self newButton label: 'Create'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'New Topic';
		initialExtent: 400 @ 200
]

{ #category : 'initialization' }
AbNewTopicDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbNewTopicDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 60 ];
				   add: titleField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 60 ];
				   add: agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'api' }
AbNewTopicDialog >> topic [
	^ topic
]

{ #category : 'private' }
AbNewTopicDialog >> agentOptions [

	^ OrderedCollection new
		  add: 'claude-agent-acp' -> #( 'claude-agent-acp' );
		  add: 'Gemini CLI' -> #( 'gemini' '--acp' );
		  add: 'OpenCode' -> #( 'opencode' 'acp' );
		  add: 'Copilot CLI' -> #( 'copilot' '--acp' '--stdio' );
		  add: 'codex-acp' -> #( 'codex-acp' );
		  yourself
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText |
	titleText := titleField text trim.
	titleText isEmpty ifTrue: [ ^ self ].
	topic := AbTopic new
		         title: titleText;
		         agentArguments: agentDropList selectedItem value;
		         yourself.
	self withWindowDo: [ :w | w close ]
]
```

- [ ] **Step 2: Import and test interactively**

Import: `/st-import AgenticBrowser-UI`

Open the browser and click "New Topic". The dialog should appear with title input and agent dropdown. Enter a title, select an agent, click Create. The topic should appear in the left sidebar with `○` icon.

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbNewTopicDialog.class.st
git commit -m "Add AbNewTopicDialog for creating topics with agent selection"
```

---

## Task 11: Integration smoke test + final export

- [ ] **Step 1: Full UI flow test**

Open the browser:
```smalltalk
AbBrowserPresenter open.
```

1. Click **+ New Topic** → dialog opens
2. Enter title "Hello test", select `claude-agent-acp`, click **Create**
3. Topic appears in sidebar with `○` icon
4. Click the topic → chat pane activates
5. Type "Say hello" in input field → click **Send**
6. Topic icon changes to `●` (working)
7. AI response streams into chat pane
8. When AI finishes: icon changes to `✓` (done)
9. Type another request → icon goes back to `●`

If the agent issues a permission request:
1. Chat shows `[⏸ AI] <permission description>`
2. Topic icon shows `⏸`
3. Input placeholder changes to "Respond to AI (yes / no / always)..."
4. Type "yes" → Send → AI resumes, icon returns to `●`

- [ ] **Step 2: Run all automated tests one final time**

Run: `/st-test AgenticBrowser-Tests`

Expected: all tests pass.

- [ ] **Step 3: Export all packages from Pharo image**

If any code was edited interactively in the image during Task 11, export it back:

```
/st-export AgenticBrowser-Core
/st-export AgenticBrowser-Handler
/st-export AgenticBrowser-UI
/st-export AgenticBrowser-Tests
/st-export BaselineOfAgenticBrowser
```

- [ ] **Step 4: Final commit**

```bash
git add src/
git commit -m "Complete Phase 1: AgenticBrowser with topic management, chat UI, and ACP integration"
```

---

## Self-review checklist (completed inline)

- **Spec coverage**: ✓ All Phase 1 requirements covered: 2-pane layout, topic status (idle/working/waitingForHuman/done), conversation-style approval, per-topic agent selection, image-based persistence via singleton, SState FSM.
- **Placeholder scan**: No TBDs or TODOs. All code steps include actual Tonel source.
- **Type consistency**: `agentArguments` (Array) used consistently in AbTopic and AbNewTopicDialog. `AbMessage >> approvalResponse` is a Symbol (`#allowAlways`, `#rejectOnce`, `#rejectAlways`) matching ACPRequestPermissionResponse method names. `status` always delegated to `stateMachine currentState name`.
- **Phase 2 items deferred correctly**: AbImageWatcher and working directory management not included in this plan.
