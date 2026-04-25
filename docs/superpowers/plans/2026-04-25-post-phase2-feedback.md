# Post-Phase-2 Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address user feedback from Phase 2 real-world testing: fix topic list update bug, simplify topic creation dialog, replace package list with prefix-based targeting, move working directory to Pharo image directory, fix image watcher to suppress import-triggered re-exports, remove toolbar buttons, and auto-prepend `/st-buddy` to first message.

**Architecture:**
- `AbTopicManager` gains an `Announcer` and fires `AbTopicAdded` on `addTopic:`, keeping the UI list in sync.
- `AbTopic` gains a persistent `topicId` (UUID string) and replaces `watchedPackages` with a `packagePrefix` string (e.g., `'ACP-*'`); `matchingPackageNames` dynamically resolves matching packages from the live image.
- `AbWorkingDirectory` path becomes `<imageDir>/agentic-browser/<safeTopicName>-<first8ofUUID>`. The `agentic-browser/` subdirectory keeps imageDir clean; the UUID suffix is stable even if the topic title changes; the directory is never renamed after creation. An `isImporting` flag suppresses re-export when the AI imports Tonel files.
- `AbImageWatcher` drops package filtering — it exports any changed package and only suppresses during import.
- UI simplifications: `AbNewTopicDialog` asks for title only; `AbTopicListPresenter` gets a right-click "Set Target Packages..." menu backed by a new `AbPackagePrefixDialog`; `AbChatPresenter` drops the export/import/test toolbar, fixes a subscription ordering bug, and auto-prepends `/st-buddy` to the first message in each topic.

**Tech Stack:** Pharo 12, Spec2, SisServer, SystemAnnouncer, UUID, Tonel

---

## File Map

```
src/
  AgenticBrowser-Core/
    AbTopicAdded.class.st          (NEW — announcement for new topic added to manager)
    AbTopicManager.class.st        (MODIFY — add announcer, fire AbTopicAdded)
    AbTopic.class.st               (MODIFY — add topicId UUID, replace watchedPackages → packagePrefix)
    AbWorkingDirectory.class.st    (MODIFY — new path convention, matchingPackageNames, isImporting)
    AbImageWatcher.class.st        (MODIFY — no package filter, check isImporting)

  AgenticBrowser-UI/
    AbPackagePrefixDialog.class.st (NEW — dialog to enter package prefix)
    AbNewTopicDialog.class.st      (MODIFY — remove package list, title-only)
    AbTopicListPresenter.class.st  (MODIFY — subscribe AbTopicAdded, right-click menu)
    AbChatPresenter.class.st       (MODIFY — remove toolbar, fix subscription, /st-buddy)

  AgenticBrowser-Tests/
    AbTopicManagerTest.class.st    (MODIFY — add AbTopicAdded test)
    AbTopicPhase2Test.class.st     (MODIFY — replace watchedPackages tests → packagePrefix + topicId)
    AbWorkingDirectoryTest.class.st (MODIFY — update path assertions, add dir-not-exists test)
    AbImageWatcherTest.class.st    (MODIFY — test import suppression, not package filter)
    AbTopicListPresenterTest.class.st (NEW — test onPackagePrefixSet: branches)
```

---

## Development Workflow (Smalltalk-specific)

All source lives as Tonel files in `src/`. The edit→import→test cycle:

1. Write/edit Tonel files in `src/`
2. Import: `mcp__plugin_smalltalk-dev_smalltalk-interop__import_package`
3. Run tests: `mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test`
4. After interactive image fixes, export back: `mcp__plugin_smalltalk-dev_smalltalk-interop__export_package`

Use the `smalltalk-developer` skill for the full workflow.

---

## Task 1: AbTopicAdded announcement + topic list bug fix

**Bug reported:** Adding a topic does not update the topic list in the UI.

**Root cause:** `onNewTopicRequest` calls `self refresh` synchronously inside a Spec2 event callback which may not trigger a widget re-render. The topic list also has no general subscription mechanism for topics added externally.

**Fix:** `AbTopicManager` fires `AbTopicAdded` on `addTopic:`; `AbTopicListPresenter` subscribes to it and uses `self defer: [...]` for all refresh calls.

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicAdded.class.st`
- Modify: `src/AgenticBrowser-Core/AbTopicManager.class.st`
- Modify: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st`

- [ ] **Step 1: Write failing test for AbTopicAdded announcement**

Add to `src/AgenticBrowser-Tests/AbTopicManagerTest.class.st` (keep all existing methods):

```
{ #category : 'tests' }
AbTopicManagerTest >> testAddTopicAnnouncesAbTopicAdded [

	| manager topic received |
	manager := AbTopicManager uniqueInstance.
	received := nil.
	manager announcer
		when: AbTopicAdded
		do: [ :ann | received := ann topic ]
		for: self.
	topic := AbTopic new title: 'Test'.
	manager addTopic: topic.
	self assert: received == topic
]
```

- [ ] **Step 2: Import test and verify it fails**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicManagerTest'
```

Expected: `testAddTopicAnnouncesAbTopicAdded` fails (AbTopicAdded does not exist).

- [ ] **Step 3: Create AbTopicAdded.class.st**

`src/AgenticBrowser-Core/AbTopicAdded.class.st`:

```
Class {
	#name : 'AbTopicAdded',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicAdded >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicAdded >> topic: anAbTopic [
	topic := anAbTopic
]
```

- [ ] **Step 4: Update AbTopicManager — add announcer + fire AbTopicAdded**

Full updated `src/AgenticBrowser-Core/AbTopicManager.class.st`:

```
Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics',
		'announcer'
	],
	#classInstVars : [
		'uniqueInstance'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'testing' }
AbTopicManager class >> resetInstance [

	uniqueInstance := nil
]

{ #category : 'instance creation' }
AbTopicManager class >> uniqueInstance [

	^ uniqueInstance ifNil: [ uniqueInstance := self new ]
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics add: anAbTopic.
	self announcer announce: (AbTopicAdded new topic: anAbTopic; yourself)
]

{ #category : 'accessing' }
AbTopicManager >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := OrderedCollection new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	topics remove: anAbTopic ifAbsent: []
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics do: aBlock
]
```

- [ ] **Step 5: Update AbTopicListPresenter — subscribe to AbTopicAdded, use defer:**

Full updated `src/AgenticBrowser-UI/AbTopicListPresenter.class.st` (context menu methods will be added in Task 6 — use this as the base for now):

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
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	newTopicButton action: [ self onNewTopicRequest ].
	self subscribeToTopicManager.
	self refresh
]

{ #category : 'layout' }
AbTopicListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: topicList;
		  add: newTopicButton
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> initializePresenters [

	topicList := self newList.
	topicList display: [ :topic | self statusIconFor: topic , ' ' , topic title ].
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'private' }
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		self defer: [ self refresh. topicList selectItem: topic ] ]
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

	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer
			when: AbTopicStatusChanged
			do: [ self defer: [ self refresh ] ]
			for: self ].
	AbTopicManager uniqueInstance announcer
		when: AbTopicAdded
		do: [ :ann |
			ann topic announcer
				when: AbTopicStatusChanged
				do: [ self defer: [ self refresh ] ]
				for: self ]
		for: self
]
```

- [ ] **Step 6: Import all changed packages and run test**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbTopicManagerTest'
```

Expected: all 5 `AbTopicManagerTest` tests pass (4 existing + 1 new).

- [ ] **Step 7: Smoke test — open browser, add topic, verify list updates**

```smalltalk
AbBrowserPresenter open.
```

Click **+ New Topic**, enter a title, click Create. The topic should appear in the list immediately without requiring any manual refresh.

- [ ] **Step 8: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicAdded.class.st \
        src/AgenticBrowser-Core/AbTopicManager.class.st \
        src/AgenticBrowser-UI/AbTopicListPresenter.class.st \
        src/AgenticBrowser-Tests/AbTopicManagerTest.class.st
git commit -m "Fix topic list not updating: add AbTopicAdded announcement and defer refresh"
```

---

## Task 2: Add topicId + replace watchedPackages with packagePrefix in AbTopic

**Changes:**
- `AbTopic` gains `topicId` (UUID string) generated once in `initialize` — stable identifier independent of title.
- `watchedPackages` collection replaced by `packagePrefix` string (e.g., `'ACP-*'`).
- `matchingPackageNames` dynamically resolves matching packages using `matchesPattern:`.

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`

- [ ] **Step 1: Write updated AbTopicPhase2Test**

Replace the full contents of `src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`:

```
Class {
	#name : 'AbTopicPhase2Test',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicPhase2Test >> testAddSystemMessage [

	| topic |
	topic := AbTopic new.
	topic addSystemMessage: 'Export complete'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: topic messages last text equals: 'Export complete'
]

{ #category : 'tests' }
AbTopicPhase2Test >> testImageWatcherLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic imageWatcher isKindOf: AbImageWatcher)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesEmptyPrefix [

	| topic |
	topic := AbTopic new.
	topic packagePrefix: ''.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesNilPrefix [

	| topic |
	topic := AbTopic new.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesWithPrefix [

	| topic names |
	topic := AbTopic new.
	topic packagePrefix: 'AgenticBrowser-*'.
	names := topic matchingPackageNames.
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Core' ])
]

{ #category : 'tests' }
AbTopicPhase2Test >> testPackagePrefixDefaultsToNil [

	self assert: AbTopic new packagePrefix isNil
]

{ #category : 'tests' }
AbTopicPhase2Test >> testSetPackagePrefix [

	| topic |
	topic := AbTopic new.
	topic packagePrefix: 'ACP-*'.
	self assert: topic packagePrefix equals: 'ACP-*'
]

{ #category : 'tests' }
AbTopicPhase2Test >> testStartWatchingAndStop [

	| topic |
	topic := AbTopic new.
	topic startWatching.
	self assert: topic imageWatcher isWatching.
	topic stopWatching.
	self deny: topic imageWatcher isWatching
]

{ #category : 'tests' }
AbTopicPhase2Test >> testTopicIdIsGeneratedOnInit [

	| topic |
	topic := AbTopic new.
	self assert: topic topicId notNil.
	self assert: topic topicId isString.
	self assert: topic topicId notEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testTopicIdIsUniquePerTopic [

	self deny: AbTopic new topicId equals: AbTopic new topicId
]

{ #category : 'tests' }
AbTopicPhase2Test >> testWorkingDirectoryLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic workingDirectory isKindOf: AbWorkingDirectory)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testWorkingDirectoryReturnsSameInstance [

	| topic |
	topic := AbTopic new.
	self assert: topic workingDirectory == topic workingDirectory
]
```

- [ ] **Step 2: Import test and verify new tests fail**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbTopicPhase2Test'
```

Expected: `testTopicIdIsGeneratedOnInit`, `testTopicIdIsUniquePerTopic`, `testMatchingPackageNamesNilPrefix`, etc. fail (no `topicId` or `packagePrefix` on `AbTopic` yet).

- [ ] **Step 3: Write updated AbTopic.class.st**

Full updated `src/AgenticBrowser-Core/AbTopic.class.st`:

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
		'topicId',
		'packagePrefix',
		'workingDirectory',
		'imageWatcher'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

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
AbTopic >> addSystemMessage: aString [

	| msg |
	msg := AbMessage sender: #system text: aString.
	messages add: msg.
	self announceMessageAdded: msg
]

{ #category : 'accessing' }
AbTopic >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbTopic >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'private' }
AbTopic >> announceMessageAdded: aMessage [

	self announcer announce: (AbMessageAdded new
		 topic: self;
		 message: aMessage;
		 yourself)
]

{ #category : 'private' }
AbTopic >> announceStatusChanged [

	self announcer announce:
		(AbTopicStatusChanged new topic: self; yourself)
]

{ #category : 'accessing' }
AbTopic >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbTopic >> client [
	^ client
]

{ #category : 'operations' }
AbTopic >> disconnect [

	client ifNotNil: [
		client disconnect.
		client := nil.
		sessionId := nil ]
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
		                 params cwd: self workingDirectory path fullName ].
	sessionId := sessionResult sessionId
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	client isNil ifTrue: [ self doConnect ]
]

{ #category : 'operations' }
AbTopic >> exportWatchedPackages [

	self workingDirectory exportAll
]

{ #category : 'accessing' }
AbTopic >> imageWatcher [

	^ imageWatcher ifNil: [ imageWatcher := AbImageWatcher forTopic: self ]
]

{ #category : 'operations' }
AbTopic >> importWatchedPackages [

	self workingDirectory importAll
]

{ #category : 'initialization' }
AbTopic >> initialize [

	title := 'Untitled'.
	agentArguments := #( 'claude-agent-acp' ).
	messages := OrderedCollection new.
	topicId := UUID new asString.
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
AbTopic >> matchingPackageNames [

	packagePrefix isNil ifTrue: [ ^ #() ].
	packagePrefix isEmpty ifTrue: [ ^ #() ].
	^ (PackageOrganizer default packages
		   select: [ :p | p name matchesPattern: packagePrefix ]
		   thenCollect: [ :p | p name ])
		  asSortedCollection asArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> packagePrefix [
	^ packagePrefix
]

{ #category : 'accessing' }
AbTopic >> packagePrefix: aString [
	packagePrefix := aString
]

{ #category : 'operations' }
AbTopic >> resolveApproval: aUserText [

	| pending response |
	pending := messages
		           detect: [ :m |
			           m isApprovalRequest and: [ m approvalResponse isNil ] ]
		           ifNone: [ ^ self ].
	response := (aUserText trimmed asLowercase includesSubstring: 'no') |
	            (aUserText trimmed asLowercase includesSubstring: 'deny') |
	            (aUserText trimmed asLowercase includesSubstring: 'reject')
		            ifTrue: [ #rejectOnce ]
		            ifFalse: [ #allowAlways ].
	pending approvalResponse: response.
	stateMachine handleEvent: #humanResponded.
	pending approvalSemaphore signal
]

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
		stateMachine handleEvent: #ended ] ] fork
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ sessionId
]

{ #category : 'operations' }
AbTopic >> startWatching [

	self imageWatcher start
]

{ #category : 'accessing' }
AbTopic >> stateMachine [
	^ stateMachine
]

{ #category : 'accessing' }
AbTopic >> status [
	^ stateMachine currentState name
]

{ #category : 'operations' }
AbTopic >> stopWatching [

	imageWatcher ifNotNil: [ imageWatcher stop ]
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
AbTopic >> topicId [
	^ topicId
]

{ #category : 'accessing' }
AbTopic >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := AbWorkingDirectory forTopic: self ]
]
```

Note: `doConnect` now uses `self workingDirectory path fullName` as the agent's CWD, so the AI operates in the correct topic directory from the start of the session.

- [ ] **Step 4: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbTopicPhase2Test'
```

Expected: all 12 tests pass.

Also run:
```
mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test — 'AgenticBrowser-Tests'
```

Expected: no regressions in `AbTopicTest` or `AbTopicManagerTest`.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st
git commit -m "Add topicId UUID and replace watchedPackages with packagePrefix + matchingPackageNames"
```

---

## Task 3: Update AbWorkingDirectory — new path, matchingPackageNames, isImporting

**Path convention:** `<imageDir>/agentic-browser/<safeTopicName>-<first8ofUUID>`

- `agentic-browser/` keeps imageDir clean as topics accumulate.
- `<safeTopicName>` is a sanitized title (alphanumeric, `-`, `_`).
- `<first8ofUUID>` from `topic topicId copyFrom: 1 to: 8` — stable even if title changes.
- Directory is created once and never renamed.

**isImporting flag:** `importAll` sets `isImporting := true` before SisServer calls and `false` after via `ensure:`.

**Files:**
- Modify: `src/AgenticBrowser-Core/AbWorkingDirectory.class.st`
- Modify: `src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st`

- [ ] **Step 1: Write updated AbWorkingDirectoryTest**

Replace the full contents of `src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st`:

```
Class {
	#name : 'AbWorkingDirectoryTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsSafeTopicName [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: (workDir directoryName includesSubstring: 'My-Cool-Feature')
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsTopicIdPrefix [

	| topic workDir expectedIdPrefix |
	topic := AbTopic new title: 'My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	expectedIdPrefix := topic topicId copyFrom: 1 to: 8.
	self assert: (workDir directoryName includesSubstring: expectedIdPrefix)
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExists [

	| topic workDir |
	topic := AbTopic new title: 'Test-WD-Creation'.
	workDir := AbWorkingDirectory forTopic: topic.
	workDir ensureExists.
	self assert: workDir path exists.
	workDir path deleteAll
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testIsImportingInitiallyFalse [

	| topic workDir |
	topic := AbTopic new title: 'Test'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: workDir isImporting
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testNewTopicWorkingDirectoryDoesNotExist [

	"A freshly-created topic must have no working directory on disk yet.
	 This is the precondition for auto-export when a package prefix is first set."

	| topic workDir |
	topic := AbTopic new title: 'Brand-New-Topic'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: workDir path exists
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testPathIsInsideAgenticBrowserSubdir [

	| topic workDir |
	topic := AbTopic new title: 'My Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self
		assert: workDir path parent fullName
		equals: (Smalltalk imageDirectory / 'agentic-browser') fullName
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameEmptyFallback [

	| topic workDir |
	topic := AbTopic new title: ''.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpecialChars [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Topic!'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'My-Cool-Topic-'
]
```

- [ ] **Step 2: Import test and verify path tests fail**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbWorkingDirectoryTest'
```

Expected: `testPathIsInsideAgenticBrowserSubdir`, `testDirectoryNameContainsTopicIdPrefix`, `testNewTopicWorkingDirectoryDoesNotExist` fail (old path still in use).

- [ ] **Step 3: Write updated AbWorkingDirectory.class.st**

Full updated `src/AgenticBrowser-Core/AbWorkingDirectory.class.st`:

```
Class {
	#name : 'AbWorkingDirectory',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isImporting'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbWorkingDirectory class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'accessing' }
AbWorkingDirectory >> directoryName [

	^ self safeTopicName , '-' , (topic topicId copyFrom: 1 to: 8)
]

{ #category : 'operations' }
AbWorkingDirectory >> ensureExists [

	self path ensureCreateDirectory
]

{ #category : 'operations' }
AbWorkingDirectory >> exportAll [

	topic matchingPackageNames do: [ :pkg | self exportPackage: pkg ]
]

{ #category : 'operations' }
AbWorkingDirectory >> exportPackage: aPackageName [

	self ensureExists.
	^ SisServer current handleExportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'operations' }
AbWorkingDirectory >> importAll [

	isImporting := true.
	[ topic matchingPackageNames do: [ :pkg | self importPackage: pkg ] ]
		ensure: [ isImporting := false ]
]

{ #category : 'operations' }
AbWorkingDirectory >> importPackage: aPackageName [

	self ensureExists.
	^ SisServer current handleImportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'initialization' }
AbWorkingDirectory >> initialize [

	isImporting := false
]

{ #category : 'accessing' }
AbWorkingDirectory >> isImporting [
	^ isImporting
]

{ #category : 'accessing' }
AbWorkingDirectory >> isImporting: aBoolean [
	isImporting := aBoolean
]

{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ Smalltalk imageDirectory / 'agentic-browser' / self directoryName
]

{ #category : 'operations' }
AbWorkingDirectory >> runAllTests [

	^ String streamContents: [ :s |
		  topic matchingPackageNames do: [ :pkg |
			  | result |
			  result := self runTests: pkg.
			  s
				  nextPutAll: pkg;
				  nextPutAll: ': ';
				  nextPutAll: (result at: 'result' ifAbsent: [ 'error' ]);
				  cr ] ]
]

{ #category : 'operations' }
AbWorkingDirectory >> runTests: aPackageName [

	^ SisServer current handleRunPackageTest: {
		  'package_name' -> aPackageName } asDictionary
]

{ #category : 'accessing' }
AbWorkingDirectory >> safeTopicName [

	| safe |
	safe := topic title collect: [ :c |
		    (c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			    ifTrue: [ c ]
			    ifFalse: [ $- ] ].
	safe isEmpty ifTrue: [ safe := 'topic' ].
	^ safe
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic [
	^ topic
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic: anAbTopic [
	topic := anAbTopic
]
```

- [ ] **Step 4: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbWorkingDirectoryTest'
```

Expected: all 8 tests pass.

Spot-check the actual path in the image:
```smalltalk
| t |
t := AbTopic new title: 'My Feature'.
t workingDirectory path fullName
"=> e.g. /home/user/pharo-12/agentic-browser/My-Feature-c1fb2254"
```

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbWorkingDirectory.class.st \
        src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st
git commit -m "AbWorkingDirectory: new path (imageDir/agentic-browser/name-uuid8), isImporting flag"
```

---

## Task 4: Fix AbImageWatcher — watch all packages, suppress import-triggered exports

**Change:** Remove the `watchedPackages` filter. The watcher now exports any changed package, suppressing only when `topic workingDirectory isImporting` is true.

**Files:**
- Modify: `src/AgenticBrowser-Core/AbImageWatcher.class.st`
- Modify: `src/AgenticBrowser-Tests/AbImageWatcherTest.class.st`

- [ ] **Step 1: Update AbImageWatcherTest**

Replace the full contents of `src/AgenticBrowser-Tests/AbImageWatcherTest.class.st`:

```
Class {
	#name : 'AbImageWatcherTest',
	#superclass : 'TestCase',
	#instVars : [
		'topic',
		'watcher'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbImageWatcherTest >> setUp [

	topic := AbTopic new.
	watcher := AbImageWatcher forTopic: topic
]

{ #category : 'running' }
AbImageWatcherTest >> tearDown [

	watcher stop.
	super tearDown
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleClassChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann classAffected: AbTopic.
	topic workingDirectory isImporting: true.
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleMethodChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	topic workingDirectory isImporting: true.
	[ watcher handleMethodChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbImageWatcherTest >> testIsWatchingInitiallyFalse [

	self deny: watcher isWatching
]

{ #category : 'tests' }
AbImageWatcherTest >> testStartSetsIsWatching [

	watcher start.
	self assert: watcher isWatching
]

{ #category : 'tests' }
AbImageWatcherTest >> testStopClearsIsWatching [

	watcher start.
	watcher stop.
	self deny: watcher isWatching
]
```

- [ ] **Step 2: Import test and verify new tests fail**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbImageWatcherTest'
```

Expected: `testHandleMethodChangeSuppressedDuringImport` and `testHandleClassChangeSuppressedDuringImport` fail (watcher still checks `watchedPackages`).

- [ ] **Step 3: Write updated AbImageWatcher.class.st**

Full updated `src/AgenticBrowser-Core/AbImageWatcher.class.st`:

```
Class {
	#name : 'AbImageWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbImageWatcher class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'event handling' }
AbImageWatcher >> handleClassChange: anAnnouncement [

	topic workingDirectory isImporting ifTrue: [ ^ self ].
	[ topic workingDirectory exportPackage: anAnnouncement classAffected package name ] fork
]

{ #category : 'event handling' }
AbImageWatcher >> handleMethodChange: anAnnouncement [

	topic workingDirectory isImporting ifTrue: [ ^ self ].
	[ topic workingDirectory exportPackage: anAnnouncement methodPackage name ] fork
]

{ #category : 'initialization' }
AbImageWatcher >> initialize [

	isWatching := false
]

{ #category : 'accessing' }
AbImageWatcher >> isWatching [
	^ isWatching
]

{ #category : 'operations' }
AbImageWatcher >> start [

	isWatching := true.
	SystemAnnouncer uniqueInstance
		when: MethodAnnouncement
		do: [ :ann | self handleMethodChange: ann ]
		for: self.
	SystemAnnouncer uniqueInstance
		when: ClassAnnouncement
		do: [ :ann | self handleClassChange: ann ]
		for: self
]

{ #category : 'operations' }
AbImageWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	isWatching := false
]

{ #category : 'accessing' }
AbImageWatcher >> topic [
	^ topic
]

{ #category : 'accessing' }
AbImageWatcher >> topic: anAbTopic [

	topic := anAbTopic.
	isWatching := false
]
```

- [ ] **Step 4: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbImageWatcherTest'
```

Expected: all 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbImageWatcher.class.st \
        src/AgenticBrowser-Tests/AbImageWatcherTest.class.st
git commit -m "AbImageWatcher: watch all packages, suppress export during import"
```

---

## Task 5: Simplify AbNewTopicDialog — title-only

**Remove** the package list multi-select. The dialog now asks for title and agent only. Package targeting is configured later via right-click on the topic.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`

- [ ] **Step 1: Write updated AbNewTopicDialog.class.st**

Full updated `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`:

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
		initialExtent: 420 @ 160
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText |
	titleText := titleField text trimmed.
	titleText isEmpty ifTrue: [ ^ self ].
	topic := AbTopic new
		         title: titleText;
		         agentArguments: agentDropList selectedItem value;
		         yourself.
	self withWindowDo: [ :w | w close ]
]

{ #category : 'api' }
AbNewTopicDialog >> topic [
	^ topic
]
```

- [ ] **Step 2: Import and smoke test**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-UI'
```

Evaluate:
```smalltalk
[ AbNewTopicDialog new openModal ] fork.
```

Expected: compact dialog (~160px tall) with Title field, Agent dropdown, Cancel/Create buttons only. Click Create — dialog closes.

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbNewTopicDialog.class.st
git commit -m "Simplify AbNewTopicDialog to title-only (remove package list)"
```

---

## Task 6: Package prefix context menu + AbPackagePrefixDialog + tests

**Add** a right-click context menu on the topic list: "Set Target Packages...". Opens `AbPackagePrefixDialog` for entering a prefix. Logic in `onPackagePrefixSet:`:
- Empty prefix or no matching packages → system message about new project development
- Matching packages + directory does not exist → auto-export (this is the first-creation path)
- Matching packages + directory exists → `UIManager confirm:` → import

**Tests:** `AbTopicListPresenterTest` covers the system message branches. The auto-export branch (first-creation) is verified by checking preconditions (matching packages exist, directory not yet created) and confirmed in the Task 8 integration smoke test.

**Files:**
- Create: `src/AgenticBrowser-UI/AbPackagePrefixDialog.class.st`
- Create: `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`
- Modify: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`

- [ ] **Step 1: Write AbTopicListPresenterTest**

`src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`:

```
Class {
	#name : 'AbTopicListPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter',
		'topic'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicListPresenterTest >> setUp [

	presenter := AbTopicListPresenter new.
	topic := AbTopic new title: 'TestTopic'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetEmptyPrefixAddsNewProjectMessage [

	topic packagePrefix: ''.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'new project' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetNoMatchAddsSystemMessage [

	topic packagePrefix: 'NonExistentXYZ99-*'.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'No packages match' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testAutoExportPreconditionsForNewTopic [

	"Verifies the preconditions for the auto-export path in onPackagePrefixSet:.
	 A freshly-created topic with a matching prefix has:
	   - at least one matching package
	   - no existing working directory on disk
	 The actual export (SisServer call) is verified in the integration smoke test."

	topic packagePrefix: 'AgenticBrowser-*'.
	self assert: topic matchingPackageNames notEmpty.
	self deny: topic workingDirectory path exists
]
```

- [ ] **Step 2: Import test and run — verify tests fail (onPackagePrefixSet: not yet defined)**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbTopicListPresenterTest'
```

Expected: all 3 tests fail (method `onPackagePrefixSet:` does not exist on `AbTopicListPresenter` yet).

- [ ] **Step 3: Create AbPackagePrefixDialog.class.st**

`src/AgenticBrowser-UI/AbPackagePrefixDialog.class.st`:

```
Class {
	#name : 'AbPackagePrefixDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'prefixField',
		'okButton',
		'cancelButton',
		'prefix'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbPackagePrefixDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbPackagePrefixDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (self newLabel label: 'Package prefix (use * as wildcard, empty = new project):')
		  withConstraints: [ :c | c height: 24 ];
		  add: prefixField
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbPackagePrefixDialog >> initializePresenters [

	prefixField := self newTextInput.
	prefixField placeholder: 'e.g. ACP-*'.

	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbPackagePrefixDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Target Packages';
		initialExtent: 400 @ 130
]

{ #category : 'private' }
AbPackagePrefixDialog >> onOkClicked [

	prefix := prefixField text trimmed.
	self withWindowDo: [ :w | w close ]
]

{ #category : 'api' }
AbPackagePrefixDialog >> prefix [
	^ prefix
]
```

- [ ] **Step 4: Update AbTopicListPresenter — add context menu + onPackagePrefixSet:**

Full updated `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`:

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

{ #category : 'private' }
AbTopicListPresenter >> buildTopicContextMenu [

	^ SpMenuPresenter new
		  addItem: [ :item |
			  item
				  name: 'Set Target Packages...';
				  action: [ self onSetTargetPackagesRequest ] ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> connectPresenters [

	topicList whenSelectionChangedDo: [ :selection |
		selection selectedItem ifNotNil: [ :topic |
			onTopicSelectedBlock ifNotNil: [ onTopicSelectedBlock value: topic ] ] ].
	topicList contextMenu: [ self buildTopicContextMenu ].
	newTopicButton action: [ self onNewTopicRequest ].
	self subscribeToTopicManager.
	self refresh
]

{ #category : 'layout' }
AbTopicListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: topicList;
		  add: newTopicButton
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbTopicListPresenter >> initializePresenters [

	topicList := self newList.
	topicList display: [ :topic | self statusIconFor: topic , ' ' , topic title ].
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'private' }
AbTopicListPresenter >> onNewTopicRequest [

	| dialog |
	dialog := AbNewTopicDialog new.
	dialog openModal.
	dialog topic ifNotNil: [ :topic |
		AbTopicManager uniqueInstance addTopic: topic.
		self defer: [ self refresh. topicList selectItem: topic ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onPackagePrefixSet: aTopic [

	| workDir matchingNames |
	workDir := aTopic workingDirectory.
	matchingNames := aTopic matchingPackageNames.
	matchingNames isEmpty
		ifTrue: [
			aTopic addSystemMessage:
				'No packages match "' , aTopic packagePrefix printString
				, '". Starting new project development.' ]
		ifFalse: [
			(workDir path exists and: [ workDir path hasChildren ])
				ifTrue: [
					(UIManager default
						 confirm:
						 'Existing topic directory found at ' , workDir path fullName
						 , '. Import packages into image?')
						ifTrue: [
							[ aTopic importWatchedPackages.
							  aTopic addSystemMessage:
								  'Imported packages from ' , workDir path fullName ] fork ] ]
				ifFalse: [
					[ aTopic exportWatchedPackages.
					  aTopic addSystemMessage:
						  'Exported ' , matchingNames size printString , ' package(s) to '
						  , workDir path fullName ] fork ] ]
]

{ #category : 'private' }
AbTopicListPresenter >> onSetTargetPackagesRequest [

	| topic dialog |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	dialog := AbPackagePrefixDialog new.
	dialog openModal.
	dialog prefix ifNil: [ ^ self ].
	topic packagePrefix: dialog prefix.
	self onPackagePrefixSet: topic
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

	AbTopicManager uniqueInstance topicsDo: [ :t |
		t announcer
			when: AbTopicStatusChanged
			do: [ self defer: [ self refresh ] ]
			for: self ].
	AbTopicManager uniqueInstance announcer
		when: AbTopicAdded
		do: [ :ann |
			ann topic announcer
				when: AbTopicStatusChanged
				do: [ self defer: [ self refresh ] ]
				for: self ]
		for: self
]
```

- [ ] **Step 5: Import all and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test — 'AbTopicListPresenterTest'
```

Expected: all 3 tests pass.

- [ ] **Step 6: Smoke test context menu + auto-export**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-UI'
```

```smalltalk
AbBrowserPresenter open.
```

1. Create a new topic "MyFeature"
2. Right-click on it → "Set Target Packages..." → enter `AgenticBrowser-*` → OK
3. Verify: system message in chat shows "Exported 4 package(s) to `.../agentic-browser/MyFeature-<uuid8>/`"
4. Verify the directory was actually created on disk:
   ```smalltalk
   AbTopicManager uniqueInstance topics first workingDirectory path exists
   ```
5. Right-click again → enter same prefix → `UIManager confirm:` should appear (dir already exists)

- [ ] **Step 7: Commit**

```bash
git add src/AgenticBrowser-UI/AbPackagePrefixDialog.class.st \
        src/AgenticBrowser-UI/AbTopicListPresenter.class.st \
        src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st
git commit -m "Add package prefix context menu, AbPackagePrefixDialog, and auto-export/import with tests"
```

---

## Task 7: Simplify AbChatPresenter — remove toolbar, fix subscription bug, add /st-buddy

**Changes:**
1. **Remove** `workDirLabel`, `exportButton`, `importButton`, `runTestsButton` and all associated methods.
2. **Fix** subscription ordering bug in `topic:` (was unsubscribing from the new topic instead of the old one).
3. **Auto-prepend** `/st-buddy ` to the first human message in each topic.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`

- [ ] **Step 1: Write updated AbChatPresenter.class.st**

Full updated `src/AgenticBrowser-UI/AbChatPresenter.class.st`:

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

{ #category : 'initialization' }
AbChatPresenter >> initializePresenters [

	messageDisplay := self newText.
	messageDisplay beNotEditable.

	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'
]

{ #category : 'private' }
AbChatPresenter >> isFirstMessageInTopic [

	^ currentTopic messages noneSatisfy: [ :m | m sender = #human ]
]

{ #category : 'private' }
AbChatPresenter >> onMessageAdded: anAbMessage [

	self rerenderMessages.
	anAbMessage isApprovalRequest ifTrue: [
		self enterApprovalMode: anAbMessage ]
]

{ #category : 'private' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	text := inputField text trimmed.
	text isEmpty ifTrue: [ ^ self ].
	inputField text: ''.
	currentTopic ifNil: [ ^ self ].
	pendingApprovalMessage
		ifNotNil: [ currentTopic resolveApproval: text ]
		ifNil: [
			promptText := self isFirstMessageInTopic
				              ifTrue: [ '/st-buddy ' , text ]
				              ifFalse: [ text ].
			currentTopic sendPrompt: promptText ]
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

{ #category : 'private' }
AbChatPresenter >> subscribeToTopic: aTopic [

	aTopic announcer
		when: AbMessageAdded
		do: [ :ann | self defer: [ self onMessageAdded: ann message ] ]
		for: self.
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self defer: [ self onTopicStatusChanged: ann topic ] ]
		for: self
]

{ #category : 'api' }
AbChatPresenter >> topic: anAbTopic [

	| previousTopic |
	previousTopic := currentTopic.
	currentTopic := anAbTopic.
	previousTopic ifNotNil: [ :t | t announcer unsubscribe: self ].
	self subscribeToTopic: anAbTopic.
	self rerenderMessages
]
```

- [ ] **Step 2: Import and smoke test**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package — 'AgenticBrowser-UI'
```

```smalltalk
AbBrowserPresenter open.
```

1. Create a topic, select it
2. Verify: no toolbar (just message area + input + Send)
3. Type "hello world" → click Send → chat shows `/st-buddy hello world`
4. Type "follow-up" → click Send → chat shows just `follow-up` (no `/st-buddy`)
5. Create a second topic, select it, select the first one again → chat re-renders correctly

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st
git commit -m "Remove toolbar, fix topic subscription ordering, auto-prepend /st-buddy to first message"
```

---

## Task 8: Full test run + export all packages + integration smoke test

- [ ] **Step 1: Run full test suite**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test — 'AgenticBrowser-Tests'
```

Expected: all tests pass. Fix any failures before proceeding.

- [ ] **Step 2: Export all packages to Tonel**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__export_package — 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__export_package — 'AgenticBrowser-Handler'
mcp__plugin_smalltalk-dev_smalltalk-interop__export_package — 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__export_package — 'AgenticBrowser-Tests'
```

- [ ] **Step 3: Integration smoke test — full workflow including auto-export**

```smalltalk
AbBrowserPresenter open.
```

Full scenario:

1. **Create topic:** Click "+ New Topic" → compact dialog → enter "IntegrationTest" → Create → topic appears in list immediately (bug fix verified)
2. **Set prefix (first time, auto-export path):** Right-click "IntegrationTest" → "Set Target Packages..." → enter `AgenticBrowser-*` → OK
3. **Verify auto-export:** System message appears in chat: "Exported 4 package(s) to `.../agentic-browser/IntegrationTest-<uuid8>/`". Check on disk that the directory exists with Tonel package subdirectories.
4. **First message gets /st-buddy:** Type "help me" → Send → chat shows `/st-buddy help me`
5. **Subsequent messages are plain:** Type "follow up" → Send → chat shows `follow up`
6. **Verify import suppresses re-export:** Evaluate `AbTopicManager uniqueInstance topics first startWatching`. Then evaluate `AbTopicManager uniqueInstance topics first importWatchedPackages`. No additional export should be triggered (watcher is quiet while import is in progress).
7. **Set prefix again (existing dir path):** Right-click → "Set Target Packages..." → enter `AgenticBrowser-*` → OK. A `UIManager confirm:` dialog should appear (directory exists).
8. **Manual edit triggers export:** Edit a method directly in the image. The watcher should export the changed package automatically. Check the Tonel file was updated in the `agentic-browser/IntegrationTest-<uuid8>/` directory.

- [ ] **Step 4: Final commit**

```bash
git add src/
git commit -m "Phase 3: post-phase2 feedback — UUID working dirs, prefix packages, /st-buddy auto-prepend"
```

---

## Self-Review

**Spec coverage from CLAUDE.local.md:**

- ✅ `NewTopicDialog` simplified to title only (Task 5)
- ✅ Working directory: `<imageDir>/agentic-browser/<safeTopicName>-<uuid8>` — subdirectory keeps imageDir clean; stable UUID survives title changes; never renamed (Task 3)
- ✅ Package targeting via right-click "Set Target Packages..." with prefix input (Task 6)
- ✅ Prefix-based package resolution replaces multi-select list (Task 2)
- ✅ Empty prefix or no match → system message about new project development (Task 6, tested in `AbTopicListPresenterTest`)
- ✅ Prefix set + no existing dir → auto-export matching packages (Task 6, preconditions tested; actual export in smoke test Task 8)
- ✅ Prefix set + existing dir → `UIManager confirm:` → import (Task 6)
- ✅ `/st-buddy` auto-prepended to first message in each topic (Task 7)
- ✅ Watcher: export any changed package (no prefix filter) (Task 4)
- ✅ Watcher: suppress export during AI import (isImporting flag) (Tasks 3 + 4, tested in `AbImageWatcherTest`)
- ✅ Bug fix: topic list not updating after add (Task 1, tested in `AbTopicManagerTest`)
- ✅ Remove Export/Import/Test UI buttons (Task 7)
- ✅ Fix subscription ordering bug in `AbChatPresenter.topic:` (Task 7)

**Placeholder scan:** No TBD, TODO, or open-ended steps found.

**Type consistency:**
- `topic matchingPackageNames` — defined in Task 2 (`AbTopic`), consumed in Tasks 3 + 6 (`AbWorkingDirectory.exportAll/importAll/runAllTests`, `onPackagePrefixSet:`)
- `topic topicId` — defined in Task 2 (`AbTopic`), consumed in Task 3 (`AbWorkingDirectory.directoryName`)
- `AbWorkingDirectory.isImporting` / `isImporting:` — defined in Task 3, checked in Task 4 (`AbImageWatcher`)
- `AbTopicAdded.topic` — defined in Task 1, consumed in Task 1 (`AbTopicListPresenter.subscribeToTopicManager`)
- `topic packagePrefix:` — defined in Task 2, set in Task 6 (`onSetTargetPackagesRequest`)
- `AbTopic.importWatchedPackages` / `exportWatchedPackages` — kept for semantic clarity; delegate to `workingDirectory.importAll` / `exportAll` which use `matchingPackageNames`
- `AbWorkingDirectory.directoryName` — defined in Task 3, used only internally in `path`; exposed for `testDirectoryNameContainsSafeTopicName` and `testDirectoryNameContainsTopicIdPrefix`
