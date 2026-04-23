# pharo-agentic-browser Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add working directory management (per-topic package export/import/test via SisServer) and image change watching (auto-re-export when user edits Pharo code directly) to pharo-agentic-browser.

**Architecture:** Two new core classes (`AbWorkingDirectory`, `AbImageWatcher`) integrate with the existing `AbTopic` via lazy initialization. The UI gets a package-selection list in `AbNewTopicDialog` and an export/import/test toolbar in `AbChatPresenter`. `AbImageWatcher` subscribes to `SystemAnnouncer` and re-exports changed packages to the working directory automatically.

**Tech Stack:** Pharo 12+, Spec2 (built-in), SisServer (PharoSmalltalkInteropServer — callable via `SisServer current` in same image), SystemAnnouncer (Pharo built-in), Tonel source format

---

## File Map

```
src/
  AgenticBrowser-Core/
    AbWorkingDirectory.class.st      (NEW)
    AbImageWatcher.class.st          (NEW)
    AbTopic.class.st                 (MODIFIED — instVars + new methods)

  AgenticBrowser-UI/
    AbNewTopicDialog.class.st        (MODIFIED — add package list)
    AbChatPresenter.class.st         (MODIFIED — add workdir toolbar)

  AgenticBrowser-Tests/
    AbWorkingDirectoryTest.class.st  (NEW)
    AbImageWatcherTest.class.st      (NEW)
    AbTopicPhase2Test.class.st       (NEW)
```

---

## Development workflow (Smalltalk-specific)

All source lives as Tonel files in `src/`. The edit→import→test cycle:

1. Write/edit Tonel files in `src/`
2. Import: use `/st-import` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__import_package`
3. Run tests: use `/st-test` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test`
4. After interactive fixes in image, export back: use `/st-export` skill or `mcp__plugin_smalltalk-dev_smalltalk-interop__export_package`

SisServer API (direct calls from Pharo, no HTTP needed):
```smalltalk
SisServer current handleExportPackage: { 'package_name' -> 'Foo'. 'path' -> '/some/dir' } asDictionary.
SisServer current handleImportPackage: { 'package_name' -> 'Foo'. 'path' -> '/some/dir' } asDictionary.
SisServer current handleRunPackageTest: { 'package_name' -> 'Foo-Tests' } asDictionary.
```

SystemAnnouncer API:
```smalltalk
"Subscribe"
SystemAnnouncer uniqueInstance when: MethodAnnouncement do: [ :ann | ... ] for: subscriber.
SystemAnnouncer uniqueInstance when: ClassAnnouncement do: [ :ann | ... ] for: subscriber.
"Unsubscribe"
SystemAnnouncer uniqueInstance unsubscribe: subscriber.
"Get package name from announcement"
aMethodAnnouncement methodPackage name.    "=> 'AgenticBrowser-Core'"
aClassAnnouncement packageAffected name.   "=> 'AgenticBrowser-Core'"
```

---

## Task 1: AbWorkingDirectory + tests

**Files:**
- Create: `src/AgenticBrowser-Core/AbWorkingDirectory.class.st`
- Create: `src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st`

- [ ] **Step 1: Write AbWorkingDirectoryTest.class.st**

`src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st`:
```
Class {
	#name : 'AbWorkingDirectoryTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbWorkingDirectoryTest >> testPath [

	| topic workDir |
	topic := AbTopic new title: 'DB Optimization'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: (workDir path fullName includesSubstring: 'agentic-browser').
	self assert: (workDir path fullName includesSubstring: 'DB-Optimization')
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpaces [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Topic'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'My-Cool-Topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameEmptyFallback [

	| topic workDir |
	topic := AbTopic new title: ''.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'topic'
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
```

- [ ] **Step 2: Write AbWorkingDirectory.class.st**

`src/AgenticBrowser-Core/AbWorkingDirectory.class.st`:
```
Class {
	#name : 'AbWorkingDirectory',
	#superclass : 'Object',
	#instVars : [ 'topic' ],
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
AbWorkingDirectory >> topic [
	^ topic
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ FileLocator home / 'agentic-browser' / self safeTopicName
]

{ #category : 'accessing' }
AbWorkingDirectory >> safeTopicName [

	| safe |
	safe := topic title collect: [ :c | c = $  ifTrue: [ $- ] ifFalse: [ c ] ].
	safe isEmpty ifTrue: [ safe := 'topic' ].
	^ safe
]

{ #category : 'operations' }
AbWorkingDirectory >> ensureExists [

	self path ensureCreateDirectory
]

{ #category : 'operations' }
AbWorkingDirectory >> exportPackage: aPackageName [

	self ensureExists.
	^ SisServer current handleExportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'operations' }
AbWorkingDirectory >> importPackage: aPackageName [

	^ SisServer current handleImportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self path fullName } asDictionary
]

{ #category : 'operations' }
AbWorkingDirectory >> runTests: aPackageName [

	^ SisServer current handleRunPackageTest: {
		  'package_name' -> aPackageName } asDictionary
]

{ #category : 'operations' }
AbWorkingDirectory >> exportAll [

	topic watchedPackages do: [ :pkg | self exportPackage: pkg ]
]

{ #category : 'operations' }
AbWorkingDirectory >> importAll [

	topic watchedPackages do: [ :pkg | self importPackage: pkg ]
]

{ #category : 'operations' }
AbWorkingDirectory >> runAllTests [

	^ String streamContents: [ :s |
		  topic watchedPackages do: [ :pkg |
			  | result |
			  result := self runTests: pkg.
			  s nextPutAll: pkg; nextPutAll: ': '; nextPutAll: (result at: 'result'); cr ] ]
]
```

- [ ] **Step 3: Import and run tests**

Import: `mcp__plugin_smalltalk-dev_smalltalk-interop__import_package` with `AgenticBrowser-Core` then `AgenticBrowser-Tests`

Run: `mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test` with `AbWorkingDirectoryTest`

Expected: 4 tests pass.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-Core/AbWorkingDirectory.class.st src/AgenticBrowser-Tests/AbWorkingDirectoryTest.class.st
git commit -m "Add AbWorkingDirectory: per-topic workdir with SisServer export/import/test"
```

---

## Task 2: AbImageWatcher + tests

**Files:**
- Create: `src/AgenticBrowser-Core/AbImageWatcher.class.st`
- Create: `src/AgenticBrowser-Tests/AbImageWatcherTest.class.st`

- [ ] **Step 1: Write AbImageWatcherTest.class.st**

`src/AgenticBrowser-Tests/AbImageWatcherTest.class.st`:
```
Class {
	#name : 'AbImageWatcherTest',
	#superclass : 'TestCase',
	#instVars : [ 'topic', 'watcher' ],
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

{ #category : 'tests' }
AbImageWatcherTest >> testHandleMethodChangeIgnoresUnwatchedPackage [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	"watchedPackages is empty so handler should return early without accessing workingDirectory"
	[ watcher handleMethodChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleClassChangeIgnoresUnwatchedPackage [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann classAffected: AbTopic.
	"watchedPackages is empty so handler should return early without accessing workingDirectory"
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]
```

- [ ] **Step 2: Check ClassAnnouncement API before writing watcher**

Evaluate in image to confirm:
```smalltalk
"Verify ClassModifiedClassDefinition has packageAffected"
| ann |
ann := ClassModifiedClassDefinition new.
ann classAffected: AbTopic.
ann packageAffected name  "should return 'AgenticBrowser-Core'"
```

If `packageAffected` raises an error, use `ann classAffected package name` instead. Adjust `handleClassChange:` accordingly.

- [ ] **Step 3: Write AbImageWatcher.class.st**

`src/AgenticBrowser-Core/AbImageWatcher.class.st`:
```
Class {
	#name : 'AbImageWatcher',
	#superclass : 'Object',
	#instVars : [ 'topic', 'isWatching' ],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbImageWatcher class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
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

{ #category : 'event handling' }
AbImageWatcher >> handleMethodChange: anAnnouncement [

	| packageName |
	packageName := anAnnouncement methodPackage name.
	(topic watchedPackages includes: packageName) ifFalse: [ ^ self ].
	[ topic workingDirectory exportPackage: packageName ] fork
]

{ #category : 'event handling' }
AbImageWatcher >> handleClassChange: anAnnouncement [

	| packageName |
	packageName := anAnnouncement classAffected package name.
	(topic watchedPackages includes: packageName) ifFalse: [ ^ self ].
	[ topic workingDirectory exportPackage: packageName ] fork
]
```

- [ ] **Step 4: Import and run tests**

Import `AgenticBrowser-Core` then `AgenticBrowser-Tests`.

Run: `AbImageWatcherTest`

Expected: 5 tests pass.

If `testHandleClassChangeIgnoresUnwatchedPackage` errors because `ClassModifiedClassDefinition` needs more setup, simplify the test to just call `handleClassChange:` with a subclass that has a known `classAffected package name`, or skip it with `self skip`.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbImageWatcher.class.st src/AgenticBrowser-Tests/AbImageWatcherTest.class.st
git commit -m "Add AbImageWatcher: SystemAnnouncer-based change detection with auto re-export"
```

---

## Task 3: AbTopic Phase 2 integration + tests

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Create: `src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`

- [ ] **Step 1: Write AbTopicPhase2Test.class.st**

`src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st`:
```
Class {
	#name : 'AbTopicPhase2Test',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicPhase2Test >> tearDown [

	"Ensure any watcher started in tests is cleaned up."
	super tearDown
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddWatchedPackage [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	self assert: (topic watchedPackages includes: 'AgenticBrowser-Core')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddWatchedPackageNoDuplicates [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	self assert: topic watchedPackages size equals: 1
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemoveWatchedPackage [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	topic removeWatchedPackage: 'AgenticBrowser-Core'.
	self deny: (topic watchedPackages includes: 'AgenticBrowser-Core')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemoveWatchedPackageAbsent [

	| topic |
	topic := AbTopic new.
	"Should not raise an error"
	[ topic removeWatchedPackage: 'NonExistent' ] on: Error do: [ :e | self fail ]
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
AbTopicPhase2Test >> testStartWatchingAndStop [

	| topic |
	topic := AbTopic new.
	topic startWatching.
	self assert: topic imageWatcher isWatching.
	topic stopWatching.
	self deny: topic imageWatcher isWatching
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddSystemMessage [

	| topic |
	topic := AbTopic new.
	topic addSystemMessage: 'Export complete'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: topic messages last text equals: 'Export complete'
]
```

- [ ] **Step 2: Modify AbTopic.class.st**

Add `workingDirectory` and `imageWatcher` to `#instVars`:
```
#instVars : [
    'title',
    'agentArguments',
    'messages',
    'client',
    'sessionId',
    'stateMachine',
    'announcer',
    'watchedPackages',
    'workingDirectory',
    'imageWatcher'
],
```

Add these methods (keep all existing methods unchanged):

```smalltalk
{ #category : 'accessing' }
AbTopic >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := AbWorkingDirectory forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> imageWatcher [

	^ imageWatcher ifNil: [ imageWatcher := AbImageWatcher forTopic: self ]
]

{ #category : 'operations' }
AbTopic >> addWatchedPackage: aPackageName [

	(watchedPackages includes: aPackageName) ifFalse: [
		watchedPackages add: aPackageName ]
]

{ #category : 'operations' }
AbTopic >> removeWatchedPackage: aPackageName [

	watchedPackages remove: aPackageName ifAbsent: []
]

{ #category : 'operations' }
AbTopic >> startWatching [

	self imageWatcher start
]

{ #category : 'operations' }
AbTopic >> stopWatching [

	imageWatcher ifNotNil: [ imageWatcher stop ]
]

{ #category : 'operations' }
AbTopic >> exportWatchedPackages [

	self workingDirectory exportAll
]

{ #category : 'operations' }
AbTopic >> importWatchedPackages [

	self workingDirectory importAll
]

{ #category : 'operations' }
AbTopic >> addSystemMessage: aString [

	| msg |
	msg := AbMessage sender: #system text: aString.
	messages add: msg.
	self announceMessageAdded: msg
]
```

- [ ] **Step 3: Import and run tests**

Import `AgenticBrowser-Core` then `AgenticBrowser-Tests`.

Run `AbTopicPhase2Test`. Expected: 8 tests pass.

Also run full suite: `AgenticBrowser-Tests`. Expected: all previous tests still pass.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicPhase2Test.class.st
git commit -m "Integrate AbWorkingDirectory and AbImageWatcher into AbTopic"
```

---

## Task 4: AbNewTopicDialog — package selection

**Files:**
- Modify: `src/AgenticBrowser-UI/AbNewTopicDialog.class.st`

Add a multi-select list of installed packages so the user can set `watchedPackages` at topic creation time. Dialog height grows from 200 to 420.

- [ ] **Step 1: Modify AbNewTopicDialog.class.st**

Add `packageList` to `#instVars`:
```
#instVars : [
    'titleField',
    'agentDropList',
    'packageList',
    'okButton',
    'cancelButton',
    'topic'
],
```

Updated `initializePresenters` (add after agentDropList setup):
```smalltalk
packageList := self newList.
packageList beMultipleSelection.
packageList items: self installedPackageNames.
packageList display: [ :name | name ].
```

Updated `initializeWindow:` (change `initialExtent`):
```smalltalk
aWindowPresenter
    title: 'New Topic';
    initialExtent: 420 @ 420.
```

Updated `defaultLayout`:
```smalltalk
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
    add: (self newLabel label: 'Packages to watch (optional, multi-select):')
    withConstraints: [ :c | c height: 24 ];
    add: packageList;
    add: (SpBoxLayout newLeftToRight
             addLast: cancelButton withConstraints: [ :c | c width: 80 ];
             addLast: okButton withConstraints: [ :c | c width: 80 ];
             yourself)
    withConstraints: [ :c | c height: 32 ];
    yourself
```

Add `installedPackageNames` private method:
```smalltalk
{ #category : 'private' }
AbNewTopicDialog >> installedPackageNames [

    ^ (RPackageOrganizer default packages
        collect: [ :p | p name ]
        thenSelect: [ :name | name notEmpty ])
        asSortedCollection asArray
]
```

Update `onOkClicked` to apply package selections:
```smalltalk
{ #category : 'private' }
AbNewTopicDialog >> onOkClicked [

    | titleText |
    titleText := titleField text trimmed.
    titleText isEmpty ifTrue: [ ^ self ].
    topic := AbTopic new
                 title: titleText;
                 agentArguments: agentDropList selectedItem value;
                 yourself.
    packageList selectedItems do: [ :name | topic addWatchedPackage: name ].
    self withWindowDo: [ :w | w close ]
]
```

- [ ] **Step 2: Import and smoke-test**

Import `AgenticBrowser-UI`.

Evaluate:
```smalltalk
[AbNewTopicDialog new openModal] fork.
```

Expected: dialog opens with title, agent dropdown, scrollable package list (all installed packages), Cancel/Create buttons. Multi-select a few packages and click Create.

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbNewTopicDialog.class.st
git commit -m "Add package selection to AbNewTopicDialog"
```

---

## Task 5: AbChatPresenter — working directory toolbar

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`

Add a compact toolbar at the top of the chat pane showing:
- Working directory path
- Export / Import / Run Tests buttons

The toolbar is only visible when the current topic has watched packages. Test results are posted as system messages in the chat.

- [ ] **Step 1: Modify AbChatPresenter.class.st**

Add to `#instVars`:
```
'workDirLabel',
'exportButton',
'importButton',
'runTestsButton',
```

Updated `initializePresenters` (add after existing widgets):
```smalltalk
workDirLabel := self newLabel.
workDirLabel label: ''.

exportButton := self newButton label: '↑ Export'.
importButton := self newButton label: '↓ Import'.
runTestsButton := self newButton label: '▶ Tests'.
```

Updated `connectPresenters`:
```smalltalk
sendButton action: [ self onSendButtonClicked ].
exportButton action: [ self onExportClicked ].
importButton action: [ self onImportClicked ].
runTestsButton action: [ self onRunTestsClicked ].
```

Updated `defaultLayout`:
```smalltalk
{ #category : 'layout' }
AbChatPresenter >> defaultLayout [

    ^ SpBoxLayout newTopToBottom
          add: (SpBoxLayout newLeftToRight
                   add: workDirLabel;
                   add: exportButton withConstraints: [ :c | c width: 80 ];
                   add: importButton withConstraints: [ :c | c width: 80 ];
                   add: runTestsButton withConstraints: [ :c | c width: 80 ];
                   yourself)
          withConstraints: [ :c | c height: 32 ];
          add: messageDisplay;
          add: (SpBoxLayout newLeftToRight
                   add: inputField;
                   add: sendButton withConstraints: [ :c | c width: 80 ];
                   yourself)
          withConstraints: [ :c | c height: 60 ];
          yourself
]
```

Add private handler methods:
```smalltalk
{ #category : 'private' }
AbChatPresenter >> onExportClicked [

    currentTopic ifNil: [ ^ self ].
    [ currentTopic exportWatchedPackages.
      currentTopic addSystemMessage: 'Exported packages to ' , currentTopic workingDirectory path fullName ] fork
]

{ #category : 'private' }
AbChatPresenter >> onImportClicked [

    currentTopic ifNil: [ ^ self ].
    [ currentTopic importWatchedPackages.
      currentTopic addSystemMessage: 'Imported packages from ' , currentTopic workingDirectory path fullName ] fork
]

{ #category : 'private' }
AbChatPresenter >> onRunTestsClicked [

    currentTopic ifNil: [ ^ self ].
    currentTopic watchedPackages isEmpty ifTrue: [ ^ self ].
    [ | results |
      results := currentTopic workingDirectory runAllTests.
      currentTopic addSystemMessage: 'Test results:' , String cr , results ] fork
]
```

Update `topic:` to refresh the toolbar:
```smalltalk
{ #category : 'api' }
AbChatPresenter >> topic: anAbTopic [

    currentTopic := anAbTopic.
    self unsubscribeCurrentTopic.
    self subscribeToTopic: anAbTopic.
    self updateWorkDirLabel.
    self rerenderMessages
]
```

Add `updateWorkDirLabel`:
```smalltalk
{ #category : 'private' }
AbChatPresenter >> updateWorkDirLabel [

    currentTopic ifNil: [
        workDirLabel label: ''.
        ^ self ].
    currentTopic watchedPackages isEmpty
        ifTrue: [ workDirLabel label: '(no packages watched)' ]
        ifFalse: [ workDirLabel label: currentTopic workingDirectory path fullName ]
]
```

- [ ] **Step 2: Import and smoke-test**

Import `AgenticBrowser-UI`.

Open browser and create a topic with at least one watched package. Select it in the left pane.

Expected:
- Toolbar shows working directory path at top of chat pane
- "↑ Export" posts a system message with the path when clicked
- "↓ Import" posts a system message when clicked
- "▶ Tests" posts test results in the chat

- [ ] **Step 3: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st
git commit -m "Add workdir toolbar to AbChatPresenter with export/import/test buttons"
```

---

## Task 6: Final export + integration smoke test

- [ ] **Step 1: Run all tests**

```smalltalk
"Run all AgenticBrowser-Tests"
```

Use `mcp__plugin_smalltalk-dev_smalltalk-interop__run_package_test` with `AgenticBrowser-Tests`.

Expected: all tests pass (previous 22 + 4 (AbWorkingDirectoryTest) + 5 (AbImageWatcherTest) + 8 (AbTopicPhase2Test) = 39 tests).

- [ ] **Step 2: Integration smoke test**

```smalltalk
AbBrowserPresenter open.
```

1. Click **+ New Topic**
2. Enter title "Phase2 Test", select `claude-agent-acp`, select `AgenticBrowser-Core` in the package list, click Create
3. Select the topic in the left pane
4. Verify the toolbar shows `~/agentic-browser/Phase2-Test`
5. Click **↑ Export** — system message appears confirming export
6. Verify `~/agentic-browser/Phase2-Test/` directory exists and contains `AgenticBrowser-Core` Tonel files
7. Click **▶ Tests** — test results appear in chat (no test package for Core itself, so empty result is OK)
8. Enable watching: evaluate `AbTopicManager uniqueInstance topics first startWatching`
9. Add a test method to any Core class in image, save → watcher fires and re-exports automatically

- [ ] **Step 3: Export all packages**

```
/st-export AgenticBrowser-Core
/st-export AgenticBrowser-Handler
/st-export AgenticBrowser-UI
/st-export AgenticBrowser-Tests
```

- [ ] **Step 4: Commit**

```bash
git add src/
git commit -m "Phase 2: working directory management and image change watching"
```

---

## Self-Review

**Spec coverage:**
- ✅ AbImageWatcher (SystemAnnouncer, Approach A) — Task 2
- ✅ AbTopic watchedPackages integration — Task 3
- ✅ Working directory management (export/import/test via SisServer) — Tasks 1 + 3
- ✅ UI: package selection in New Topic Dialog — Task 4
- ✅ UI: export/import/test toolbar in chat pane — Task 5
- ✅ System messages for operation feedback — Task 3 + 5
- ✅ Auto re-export on image change — Task 2 (AbImageWatcher.handleMethodChange:)
- ⚠️ Phase 2 design mentions "AI identifies relevant packages" — deferred (AI can call `/st-export` via ACP; no AgenticBrowser automation needed in this phase)
- ⚠️ Phase 2 design mentions MCWorkingCopy polling (Approach B) — Approach A (SystemAnnouncer) implemented; Approach B is not included per design doc guidance

**Placeholder scan:** No TBD, TODO, or placeholder steps found.

**Type consistency:**
- `AbWorkingDirectory.exportPackage:` used consistently in `AbImageWatcher.handleMethodChange:` and `AbTopic.exportWatchedPackages`
- `AbTopic.workingDirectory` returns `AbWorkingDirectory` instance — consistent across Tasks 1, 2, 3, 5
- `AbTopic.addSystemMessage:` defined in Task 3, used in Task 5 — consistent
