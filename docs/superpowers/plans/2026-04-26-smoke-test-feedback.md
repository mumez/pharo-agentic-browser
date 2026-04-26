# Post-Smoke-Test Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the updated feedback from Phase 2 smoke testing: topic rename/delete, rename AbImageWatcher to AbTopicRelatedPackagesWatcher with chat notifications and user confirmation, plural packagePrefixes, auto-detect prefixes from existing directories, and UI method category cleanup.

**Architecture:**
- `AbTopic` replaces the singular `packagePrefix` (String) with `packagePrefixes` (Array of Strings) to support targeting multiple package families like `#('ACP-*' 'BaselineOfACP')`.
- `AbTopicRelatedPackagesWatcher` (renamed from `AbImageWatcher`) watches all image changes, inserts system messages into the topic's chat when relevant packages change, and pauses for user confirmation before exporting. Changes from packages outside `packagePrefixes` trigger an in-chat decision (ignore or add prefix).
- `AbTopicListPresenter` gains right-click menu items for Rename and Delete (with confirmation).
- `AbNewTopicDialog` gains an optional working directory field; when set to an existing directory, it scans subdirectories to auto-suggest `packagePrefixes`.
- UI method categories are cleaned up: `'api'` is split into `'accessing'`, `'actions'`, `'refreshing'`, etc.

**Tech Stack:** Pharo 12, Spec2, SisServer, SystemAnnouncer, UUID, Tonel

---

## File Map

```
src/
  AgenticBrowser-Core/
    AbTopic.class.st                        (MODIFY — packagePrefix→packagePrefixes)
    AbTopicRelatedPackagesWatcher.class.st  (NEW — renamed from AbImageWatcher with chat integration + confirmation)
    AbImageWatcher.class.st                 (DELETE — superseded by AbTopicRelatedPackagesWatcher)
    AbWorkingDirectory.class.st             (MODIFY — use packagePrefixes)

  AgenticBrowser-UI/
    AbTopicListPresenter.class.st           (MODIFY — rename, delete menu items; fix method categories)
    AbChatPresenter.class.st                (MODIFY — cancel button, method categories)
    AbNewTopicDialog.class.st               (MODIFY — working dir option, auto-detect prefixes)
    AbPackagePrefixDialog.class.st          (MODIFY — method categories)
    AbBrowserPresenter.class.st             (MODIFY — method categories)

  AgenticBrowser-Tests/
    AbTopicPhase2Test.class.st              (MODIFY — packagePrefixes tests)
    AbImageWatcherTest.class.st             (DELETE → replace with AbTopicRelatedPackagesWatcherTest)
    AbTopicRelatedPackagesWatcherTest.class.st (NEW)
    AbTopicListPresenterTest.class.st       (MODIFY — rename/delete tests)
    AbNewTopicDialogTest.class.st           (NEW — auto-detect prefix tests)
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

## Task 1: AbTopic — packagePrefix → packagePrefixes

**Changes:**
- `packagePrefix` (String) → `packagePrefixes` (OrderedCollection of Strings)
- `matchingPackageNames` collects packages matching **any** prefix in the collection
- Add `addPackagePrefix:`, `removePackagePrefix:`, `hasPackagePrefix:` helpers
- Update `initialize` to set `packagePrefixes := OrderedCollection new`

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`

- [ ] **Step 1: Write updated AbTopicPhase2Test**

Replace full contents of `src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`:

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
AbTopicPhase2Test >> testAddPackagePrefix [

	| topic |
	topic := AbTopic new.
	topic addPackagePrefix: 'ACP-*'.
	topic addPackagePrefix: 'BaselineOfACP'.
	self assert: topic packagePrefixes size equals: 2.
	self assert: (topic hasPackagePrefix: 'ACP-*').
	self assert: (topic hasPackagePrefix: 'BaselineOfACP')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testImageWatcherLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic imageWatcher isKindOf: AbTopicRelatedPackagesWatcher)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesEmptyPrefixes [

	| topic |
	topic := AbTopic new.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesMultiplePrefixes [

	| topic names |
	topic := AbTopic new.
	topic addPackagePrefix: 'AgenticBrowser-*'.
	topic addPackagePrefix: 'BaselineOfAgenticBrowser'.
	names := topic matchingPackageNames.
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Core' ]).
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Tests' ])
]

{ #category : 'tests' }
AbTopicPhase2Test >> testPackagePrefixesDefaultsToEmpty [

	self assert: AbTopic new packagePrefixes isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemovePackagePrefix [

	| topic |
	topic := AbTopic new.
	topic addPackagePrefix: 'ACP-*'.
	topic removePackagePrefix: 'ACP-*'.
	self deny: (topic hasPackagePrefix: 'ACP-*')
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

{ #category : 'tests' }
AbTopicPhase2Test >> testWorkingDirectoryWasCreatedForConnection [

	| topic path |
	topic := AbTopic new title: 'money calc'.
	path := topic workingDirectory path.
	self deny: path exists.
	self deny: topic imageWatcher isWatching.
	topic ensureWorkingDirectoryForConnection.
	self assert: path exists.
	self assert: topic imageWatcher isWatching.
	topic stopWatching.
	path deleteAll
]
```

- [ ] **Step 2: Import test and verify new tests fail**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicPhase2Test'
```

Expected: `testPackagePrefixesDefaultsToEmpty`, `testAddPackagePrefix`, `testMatchingPackageNamesMultiplePrefixes`, `testRemovePackagePrefix` fail (no `packagePrefixes` on `AbTopic` yet).

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
		'packagePrefixes',
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
AbTopic >> addPackagePrefix: aString [

	(packagePrefixes includes: aString) ifFalse: [
		packagePrefixes add: aString ]
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
						 params cwd: self ensureWorkingDirectoryForConnection ].
	sessionId := sessionResult sessionId
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	client isNil ifTrue: [ self doConnect ]
]

{ #category : 'private' }
AbTopic >> ensureWorkingDirectoryForConnection [

	self workingDirectory ensureExists.
	self imageWatcher isWatching ifFalse: [ self startWatching ].
	^ self workingDirectory path fullName
]

{ #category : 'operations' }
AbTopic >> exportWatchedPackages [

	self workingDirectory exportAll
]

{ #category : 'accessing' }
AbTopic >> imageWatcher [

	^ imageWatcher ifNil: [ imageWatcher := AbTopicRelatedPackagesWatcher forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> hasPackagePrefix: aString [

	^ packagePrefixes includes: aString
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
	packagePrefixes := OrderedCollection new.
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

	packagePrefixes isEmpty ifTrue: [ ^ #() ].
	^ (PackageOrganizer default packages
			 select: [ :p |
				 packagePrefixes anySatisfy: [ :prefix |
					 prefix match: p name asString ] ]
			 thenCollect: [ :p | p name asString ])
		  asSortedCollection asArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> packagePrefixes [
	^ packagePrefixes
]

{ #category : 'accessing' }
AbTopic >> packagePrefixes: aCollection [
	packagePrefixes := aCollection asOrderedCollection
]

{ #category : 'operations' }
AbTopic >> removePackagePrefix: aString [

	packagePrefixes remove: aString ifAbsent: []
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

- [ ] **Step 4: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicPhase2Test'
```

Expected: all tests pass.

Also run:
```
mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test with package_name: 'AgenticBrowser-Tests'
```

Expected: no regressions in other test classes.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st
git commit -m "feat: replace packagePrefix with packagePrefixes (Array)"
```

---

## Task 2: Rename AbImageWatcher → AbTopicRelatedPackagesWatcher with chat integration

**Changes:**
1. Rename class `AbImageWatcher` → `AbTopicRelatedPackagesWatcher`
2. On any method/class change:
   - If `isImporting` is true → suppress (existing behavior)
   - Else, determine the changed package name
   - If the package matches any of `topic packagePrefixes`:
     - Insert system message: `[<packageName> が変更されたので .st ファイルを更新しました]`
     - Export the package (in background)
   - If the package does **not** match any prefix:
     - Insert system message asking user to choose:
       `"Package '<packageName>' was modified but does not match any tracked prefix. Ignore this change, or add '<packageName>' to tracked prefixes?"`
     - Use `UIManager confirm:` to block and ask. If user says yes → `topic addPackagePrefix:` with the exact package name, then export.
     - **Important:** The default should be to ask; an "allow all" auto-accept setting can be added later.
3. Delete old `AbImageWatcher.class.st` and `AbImageWatcherTest.class.st`

**Files:**
- Create: `src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`
- Create: `src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st`
- Delete: `src/AgenticBrowser-Core/AbImageWatcher.class.st`
- Delete: `src/AgenticBrowser-Tests/AbImageWatcherTest.class.st`

- [ ] **Step 1: Write AbTopicRelatedPackagesWatcherTest**

`src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st`:

```
Class {
	#name : 'AbTopicRelatedPackagesWatcherTest',
	#superclass : 'TestCase',
	#instVars : [
		'topic',
		'watcher'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicRelatedPackagesWatcherTest >> setUp [

	topic := AbTopic new.
	watcher := AbTopicRelatedPackagesWatcher forTopic: topic
]

{ #category : 'running' }
AbTopicRelatedPackagesWatcherTest >> tearDown [

	watcher stop.
	super tearDown
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann newClassDefinition: AbTopic.
	topic workingDirectory isImporting: true.
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleMethodChangeSuppressedDuringImport [

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
AbTopicRelatedPackagesWatcherTest >> testIsWatchingInitiallyFalse [

	self deny: watcher isWatching
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStartSetsIsWatching [

	watcher start.
	self assert: watcher isWatching
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStopClearsIsWatching [

	watcher start.
	watcher stop.
	self deny: watcher isWatching
]
```

- [ ] **Step 2: Import test and verify it fails**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicRelatedPackagesWatcherTest'
```

Expected: fails because `AbTopicRelatedPackagesWatcher` does not exist yet.

- [ ] **Step 3: Write AbTopicRelatedPackagesWatcher.class.st**

`src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st`:

```
Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicRelatedPackagesWatcher class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> announceChangeAndExport: aPackageName [

	topic addSystemMessage:
		aPackageName , ' が変更されたので .st ファイルを更新しました'.
	[ topic workingDirectory exportPackage: aPackageName ] fork
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleClassChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImporting ifTrue: [ ^ self ].
	pkgName := anAnnouncement classAffected package name asString.
	self handlePackageChange: pkgName
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleMethodChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImporting ifTrue: [ ^ self ].
	pkgName := anAnnouncement methodPackage name asString.
	self handlePackageChange: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handlePackageChange: aPackageName [

	| matchesPrefix |
	matchesPrefix := topic packagePrefixes anySatisfy: [ :prefix |
						 prefix match: aPackageName ].
	matchesPrefix
		ifTrue: [ self announceChangeAndExport: aPackageName ]
		ifFalse: [
			(UIManager default confirm:
				 'Package ''' , aPackageName
				 , ''' was modified but does not match any tracked prefix.' , String cr
				 , 'Add this package to tracked prefixes and export?')
				ifTrue: [
					topic addPackagePrefix: aPackageName.
					self announceChangeAndExport: aPackageName ] ]
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	isWatching := false
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> isWatching [
	^ isWatching
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

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
AbTopicRelatedPackagesWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	isWatching := false
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic: anAbTopic [

	topic := anAbTopic.
	isWatching := false
]
```

- [ ] **Step 4: Delete old AbImageWatcher files**

```bash
rm src/AgenticBrowser-Core/AbImageWatcher.class.st
rm src/AgenticBrowser-Tests/AbImageWatcherTest.class.st
```

- [ ] **Step 5: Import all and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicRelatedPackagesWatcherTest'
```

Expected: all 5 tests pass.

Also run:
```
mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test with package_name: 'AgenticBrowser-Tests'
```

Expected: no regressions.

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicRelatedPackagesWatcher.class.st \
        src/AgenticBrowser-Tests/AbTopicRelatedPackagesWatcherTest.class.st
git rm src/AgenticBrowser-Core/AbImageWatcher.class.st \
       src/AgenticBrowser-Tests/AbImageWatcherTest.class.st
git commit -m "feat: rename AbImageWatcher to AbTopicRelatedPackagesWatcher with chat notifications and user confirmation"
```

---

## Task 3: AbTopicListPresenter — Rename, Delete, and method category cleanup

**Changes:**
1. Add right-click menu items: **Rename...** and **Delete** (with confirmation dialog)
2. Rename: open a simple `SpRequestDialog` or custom dialog to edit the title
3. Delete: `UIManager confirm:` then `AbTopicManager uniqueInstance removeTopic:`
4. Clean up method categories: `'api'` → `'accessing'` or `'actions'`, `'private'` stays

**Files:**
- Modify: `src/AgenticBrowser-UI/AbTopicListPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`

- [ ] **Step 1: Write updated AbTopicListPresenterTest**

Replace full contents of `src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st`:

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
AbTopicListPresenterTest >> testAutoExportPreconditionsForNewTopic [

	"Verifies the preconditions for the auto-export path in onPackagePrefixSet:.
	 A freshly-created topic with a matching prefix has:
	   - at least one matching package
	   - no existing working directory on disk
	 The actual export (SisServer call) is verified in the integration smoke test."

	topic addPackagePrefix: 'AgenticBrowser-*'.
	self assert: topic matchingPackageNames notEmpty.
	self deny: topic workingDirectory path exists
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetEmptyPrefixAddsNewProjectMessage [

	topic packagePrefixes: #( '' ).
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'new project' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetNoMatchAddsSystemMessage [

	topic addPackagePrefix: 'NonExistentXYZ99-*'.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'No packages match' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForReturnsIconAndTitle [

	self assert: (presenter topicListLabelFor: topic) equals: '○ TestTopic'
]
```

- [ ] **Step 2: Write updated AbTopicListPresenter.class.st**

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
		  addItem: [ :item |
			  item
				  name: 'Rename...';
				  action: [ self onRenameTopicRequest ] ];
		  addItem: [ :item |
			  item
				  name: 'Delete';
				  action: [ self onDeleteTopicRequest ] ];
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
	topicList display: [ :topic | self topicListLabelFor: topic ].
	newTopicButton := self newButton.
	newTopicButton label: '+ New Topic'
]

{ #category : 'private' }
AbTopicListPresenter >> onDeleteTopicRequest [

	| topic |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	(UIManager default
		 confirm: 'Delete topic "' , topic title , '"?'
		 label: 'Confirm Delete')
		ifTrue: [
			AbTopicManager uniqueInstance removeTopic: topic.
			self defer: [ self refresh ] ]
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
				'No packages match ' , aTopic packagePrefixes printString
				, '. Starting new project development.' ]
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
AbTopicListPresenter >> onRenameTopicRequest [

	| topic newTitle |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	newTitle := UIManager default
				    request: 'New title:'
				    initialAnswer: topic title
				    title: 'Rename Topic'.
	(newTitle isNil or: [ newTitle trimmed isEmpty ]) ifTrue: [ ^ self ].
	topic title: newTitle trimmed.
	self defer: [ self refresh ]
]

{ #category : 'private' }
AbTopicListPresenter >> onSetTargetPackagesRequest [

	| topic dialog |
	topic := topicList selectedItem.
	topic ifNil: [ ^ self ].
	dialog := AbPackagePrefixDialog new.
	dialog openModal.
	dialog prefix ifNil: [ ^ self ].
	topic packagePrefixes: (dialog prefix isEmpty
							  ifTrue: [ OrderedCollection new ]
							  ifFalse: [ OrderedCollection with: dialog prefix ]).
	self onPackagePrefixSet: topic
]

{ #category : 'actions' }
AbTopicListPresenter >> onTopicSelected: aBlock [

	onTopicSelectedBlock := aBlock
]

{ #category : 'refreshing' }
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

{ #category : 'private' }
AbTopicListPresenter >> topicListLabelFor: aTopic [

	^ (self statusIconFor: aTopic) , ' ' , aTopic title
]
```

- [ ] **Step 3: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbTopicListPresenterTest'
```

Expected: all tests pass.

- [ ] **Step 4: Smoke test**

```smalltalk
AbBrowserPresenter open.
```

1. Create a topic
2. Right-click → **Rename...** → change title → list updates
3. Right-click → **Delete** → confirm → topic removed from list

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbTopicListPresenter.class.st \
        src/AgenticBrowser-Tests/AbTopicListPresenterTest.class.st
git commit -m "feat: add topic rename/delete to context menu; clean up method categories"
```

---

## Task 4: AbNewTopicDialog — existing working directory + auto-detect package prefixes

**Changes:**
1. Add an optional **Working Directory** text field
2. If the user enters an existing directory path, scan subdirectories (e.g., `src/ACP-xxx`) and auto-suggest `packagePrefixes`
3. When the directory path is provided, override the default `AbWorkingDirectory` path behavior (or store it separately)

**Simplification for this plan:** The working directory override is stored on `AbTopic` as `customWorkingDirectoryPath`. If set, `AbWorkingDirectory>>path` uses it instead of the default `imageDirectory/agentic-browser/...` location. Auto-detection scans the provided directory for `src/` subfolders matching patterns.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Core/AbWorkingDirectory.class.st`
- Create: `src/AgenticBrowser-Tests/AbNewTopicDialogTest.class.st`

- [ ] **Step 1: Add customWorkingDirectoryPath to AbTopic**

Add to `AbTopic` instVars: `customWorkingDirectoryPath`

Add methods to `src/AgenticBrowser-Core/AbTopic.class.st`:

```
{ #category : 'accessing' }
AbTopic >> customWorkingDirectoryPath [
	^ customWorkingDirectoryPath
]

{ #category : 'accessing' }
AbTopic >> customWorkingDirectoryPath: aString [
	customWorkingDirectoryPath := aString
]
```

- [ ] **Step 2: Update AbWorkingDirectory to respect custom path**

Modify `path` method in `src/AgenticBrowser-Core/AbWorkingDirectory.class.st`:

```
{ #category : 'accessing' }
AbWorkingDirectory >> path [

	topic customWorkingDirectoryPath ifNotNil: [ :p |
		^ p asFileReference ].
	^ Smalltalk imageDirectory / 'agentic-browser' / self directoryName
]
```

- [ ] **Step 3: Write AbNewTopicDialogTest**

`src/AgenticBrowser-Tests/AbNewTopicDialogTest.class.st`:

```
Class {
	#name : 'AbNewTopicDialogTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbNewTopicDialogTest >> testDetectPrefixesFromDirectoryWithSrc [

	| dialog prefixes |
	dialog := AbNewTopicDialog new.
	prefixes := dialog detectPackagePrefixesFromDirectory:
		            '/tmp/fake-project/src/ACP-Core src/ACP-UI src/BaselineOfACP'.
	self assert: (prefixes includes: 'ACP-*').
	self assert: (prefixes includes: 'BaselineOfACP')
]

{ #category : 'tests' }
AbNewTopicDialogTest >> testDetectPrefixesReturnsEmptyForNonExistentDir [

	| dialog prefixes |
	dialog := AbNewTopicDialog new.
	prefixes := dialog detectPackagePrefixesFromDirectory: '/nonexistent/path'.
	self assert: prefixes isEmpty
]
```

- [ ] **Step 4: Write updated AbNewTopicDialog.class.st**

Full updated `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`:

```
Class {
	#name : 'AbNewTopicDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleField',
		'agentDropList',
		'workingDirField',
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
				   add: (self newLabel label: 'Title:') withConstraints: [ :c | c width: 80 ];
				   add: titleField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 80 ];
				   add: agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Working dir:') withConstraints: [ :c | c width: 80 ];
				   add: workingDirField;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'operations' }
AbNewTopicDialog >> detectPackagePrefixesFromDirectory: aPathString [

	| dir srcDir prefixes |
	dir := aPathString asFileReference.
	dir exists ifFalse: [ ^ #() ].
	prefixes := OrderedCollection new.
	srcDir := dir / 'src'.
	srcDir exists ifFalse: [ ^ #() ].
	srcDir directories do: [ :sub |
		| name |
		name := sub basename.
		(name beginsWith: 'BaselineOf')
			ifTrue: [ prefixes add: name ]
			ifFalse: [
				| hyphenPos base |
				hyphenPos := name indexOf: $-.
				hyphenPos > 1 ifTrue: [
					base := name copyFrom: 1 to: hyphenPos - 1.
					(prefixes includes: base , '-*') ifFalse: [
						prefixes add: base , '-*' ] ] ] ].
	^ prefixes asArray
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializePresenters [

	titleField := self newTextInput.
	titleField placeholder: 'Topic title...'.

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].

	workingDirField := self newTextInput.
	workingDirField placeholder: '(optional) Path to existing project directory...'.

	okButton := self newButton label: 'Create'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbNewTopicDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'New Topic';
		initialExtent: 480 @ 200
]

{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

	| titleText dirPath detectedPrefixes |
	titleText := titleField text trimmed.
	titleText isEmpty ifTrue: [ ^ self ].
	topic := AbTopic new
				 title: titleText;
				 agentArguments: agentDropList selectedItem value;
				 yourself.
	dirPath := workingDirField text trimmed.
	dirPath isEmpty ifFalse: [
		topic customWorkingDirectoryPath: dirPath.
		detectedPrefixes := self detectPackagePrefixesFromDirectory: dirPath.
		topic packagePrefixes: detectedPrefixes ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'accessing' }
AbNewTopicDialog >> topic [
	^ topic
]
```

- [ ] **Step 5: Import and run tests**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Core'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-Tests'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbNewTopicDialogTest'
```

Expected: 2 tests pass.

- [ ] **Step 6: Smoke test**

```smalltalk
[ AbNewTopicDialog new openModal ] fork.
```

Enter a title, enter an existing project directory path in Working dir, click Create. Verify topic has auto-detected prefixes.

- [ ] **Step 7: Commit**

```bash
git add src/AgenticBrowser-UI/AbNewTopicDialog.class.st \
        src/AgenticBrowser-Core/AbTopic.class.st \
        src/AgenticBrowser-Core/AbWorkingDirectory.class.st \
        src/AgenticBrowser-Tests/AbNewTopicDialogTest.class.st
git commit -m "feat: AbNewTopicDialog supports existing working directory with auto-detected package prefixes"
```

---

## Task 5: UI Method Category Cleanup

**Changes:** Replace `'api'` method categories across UI files with more descriptive ones (`'accessing'`, `'actions'`, `'refreshing'`).

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`
- Modify: `src/AgenticBrowser-UI/AbPackagePrefixDialog.class.st`
- Modify: `src/AgenticBrowser-UI/AbBrowserPresenter.class.st`

- [ ] **Step 1: Update AbChatPresenter.class.st**

Replace method categories:
- `'api'` on `enterApprovalMode:` → `'actions'`
- `'api'` on `exitApprovalMode` → `'actions'`
- `'api'` on `topic:` → `'accessing'`

Full file `src/AgenticBrowser-UI/AbChatPresenter.class.st`:

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

{ #category : 'actions' }
AbChatPresenter >> enterApprovalMode: anAbMessage [

	pendingApprovalMessage := anAbMessage.
	inputField placeholder: 'Respond to AI (yes / no / always)...'.
	inputField text: ''
]

{ #category : 'actions' }
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

{ #category : 'accessing' }
AbChatPresenter >> topic: anAbTopic [

	| previousTopic |
	previousTopic := currentTopic.
	currentTopic := anAbTopic.
	previousTopic ifNotNil: [ :t | t announcer unsubscribe: self ].
	self subscribeToTopic: anAbTopic.
	self rerenderMessages
]
```

- [ ] **Step 2: Update AbPackagePrefixDialog.class.st**

Change `'api'` on `prefix` → `'accessing'`.

- [ ] **Step 3: Update AbBrowserPresenter.class.st**

No `'api'` categories here, but verify consistency. No changes needed unless existing categories need adjustment.

- [ ] **Step 4: Import and verify no regressions**

```
mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_name: 'AgenticBrowser-UI'
mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test with package_name: 'AgenticBrowser-Tests'
```

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st \
        src/AgenticBrowser-UI/AbPackagePrefixDialog.class.st
git commit -m "refactor: replace 'api' method category with 'accessing', 'actions', 'refreshing'"
```

---

## Task 6: Low-Priority UI Improvements (Optional)

**These can be deferred or implemented individually after the core tasks above.**

### 6a. Show current agent in topic list
Add agent info to `AbTopicListPresenter>>topicListLabelFor:` or tooltip.

### 6b. Allow changing agent
Add "Set Agent..." to context menu, similar to package prefix dialog.

### 6c. Show model info
Display in status bar or tooltip; requires `AbTopic` to store model info from AI initialization response.

### 6d. Cancel button in chat
Add small cancel button next to Send in `AbChatPresenter`. Calls `currentTopic disconnect` or interrupts the fork.

### 6e. Distinguish AI think vs normal speech
Add `isThink` flag to `AbMessage`. Update `AbTopic>>addAiTextChunk:` to detect `<think>` tags or think blocks. Update `AbMessage>>displayText` to show `[AI(think)]` or dim color.

---

## Self-Review Checklist

**1. Spec coverage:**
- ✅ Topic rename — Task 3
- ✅ Topic delete with confirmation — Task 3
- ✅ AbImageWatcher rename — Task 2
- ✅ Chat notification on package change — Task 2
- ✅ User confirmation before export — Task 2
- ✅ Non-matching package handling (ignore/add prefix) — Task 2
- ✅ packagePrefix → packagePrefixes — Task 1
- ✅ Existing working directory support — Task 4
- ✅ Auto-detect package prefixes from directory — Task 4
- ✅ Method category cleanup ('api' → specific) — Task 5
- ⏸ Low-priority UI improvements — Task 6 (deferred)

**2. Placeholder scan:**
- No "TBD", "TODO", "implement later" found.
- All steps contain actual code or exact commands.

**3. Type consistency:**
- `packagePrefixes` is `OrderedCollection` throughout.
- `AbTopicRelatedPackagesWatcher` replaces `AbImageWatcher` consistently.
- `customWorkingDirectoryPath` is a String stored on `AbTopic`.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-04-26-smoke-test-feedback.md`.**

**Two execution options:**

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration
2. **Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
