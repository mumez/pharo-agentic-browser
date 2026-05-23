# AbSettingsPresenter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `AbSettingsPresenter` — a dialog that lets the user view and edit any `AbSettings` instance (the global default or a topic-local copy).

**Architecture:** `AbSettingsPresenter` is a `SpPresenter` that accepts a settings object via `settings:`. It renders one row per setting (integer fields, drop lists, checkbox). Save/Cancel buttons apply or discard edits. An `onSaveAction:` callback lets callers hook persistence (e.g., `AbSettings save` for global settings). The presenter is opened from `AbBrowserPresenter` via a menu item.

**Tech Stack:** Spec2 / SpPresenter, existing `AbSettings`, `AbConstants`, `AbBrowserPresenter`.

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `src/AgenticBrowser-UI/AbSettingsPresenter.class.st` | Create | The new presenter |
| `src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st` | Create | Unit tests |
| `src/AgenticBrowser-UI/AbBrowserPresenter.class.st` | Modify | Add "Settings…" menu item |

---

### Task 1: AbSettingsPresenter skeleton

**Files:**
- Create: `src/AgenticBrowser-UI/AbSettingsPresenter.class.st`
- Create: `src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st`

- [ ] **Step 1: Write failing tests**

```smalltalk
"AbSettingsPresenterTest"
Class {
	#name : 'AbSettingsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSettingsPresenterTest >> setUp [
	super setUp.
	presenter := AbSettingsPresenter new.
	presenter settings: AbSettings new.
	presenter initializePresenters
]

{ #category : 'running' }
AbSettingsPresenterTest >> tearDown [
	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSettingsIsAssigned [
	self assert: presenter settings isKindOf: AbSettings
]
```

- [ ] **Step 2: Lint test file, import tests, run to confirm failure**

```
/st-lint src/AgenticBrowser-Tests
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: error — `AbSettingsPresenter` does not exist.

- [ ] **Step 3: Write minimal class**

```smalltalk
"src/AgenticBrowser-UI/AbSettingsPresenter.class.st"
Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'settings',
		'saveAction'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AbSettingsPresenter class >> openOn: anAbSettings [
	| presenter |
	presenter := self new.
	presenter settings: anAbSettings.
	presenter open.
	^ presenter
]

{ #category : 'accessing' }
AbSettingsPresenter >> settings [
	^ settings
]

{ #category : 'accessing' }
AbSettingsPresenter >> settings: anAbSettings [
	settings := anAbSettings
]

{ #category : 'actions' }
AbSettingsPresenter >> onSaveAction: aBlock [
	saveAction := aBlock
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializePresenters [
	super initializePresenters
]

{ #category : 'initialization' }
AbSettingsPresenter >> initialize [
	super initialize.
	saveAction := []
]

{ #category : 'layout' }
AbSettingsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Settings';
		initialExtent: 420 @ 320
]
```

- [ ] **Step 4: Lint, import both packages, run tests**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: 1 passed.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbSettingsPresenter.class.st \
        src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st
git commit -m "feat: add AbSettingsPresenter skeleton"
```

---

### Task 2: Integer fields (timeout seconds)

Three settings need integer inputs: `watcherMessageThrottleSeconds`, `aiPermissionWaitTimeoutSeconds`, `exportApprovalWaitTimeoutSeconds`.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbSettingsPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st`

- [ ] **Step 1: Add failing tests**

```smalltalk
{ #category : 'tests' }
AbSettingsPresenterTest >> testWatcherThrottleFieldShowsDefaultValue [
	self assert: presenter watcherThrottleField text equals: '2'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testAiTimeoutFieldShowsDefaultValue [
	self assert: presenter aiTimeoutField text equals: '1800'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testExportTimeoutFieldShowsDefaultValue [
	self assert: presenter exportTimeoutField text equals: '30'
]
```

- [ ] **Step 2: Import tests, run to confirm failure**

```
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```

- [ ] **Step 3: Add instVars and integer field methods**

Add `watcherThrottleField`, `aiTimeoutField`, `exportTimeoutField` to `#instVars`.

Update `initializePresenters`:
```smalltalk
{ #category : 'initialization' }
AbSettingsPresenter >> initializePresenters [
	super initializePresenters.
	watcherThrottleField := self newTextInput.
	watcherThrottleField text: self settings watcherMessageThrottleSeconds printString.

	aiTimeoutField := self newTextInput.
	aiTimeoutField text: self settings aiPermissionWaitTimeoutSeconds printString.

	exportTimeoutField := self newTextInput.
	exportTimeoutField text: self settings exportApprovalWaitTimeoutSeconds printString
]
```

Add accessors:
```smalltalk
{ #category : 'accessing' }
AbSettingsPresenter >> watcherThrottleField [ ^ watcherThrottleField ]

{ #category : 'accessing' }
AbSettingsPresenter >> aiTimeoutField [ ^ aiTimeoutField ]

{ #category : 'accessing' }
AbSettingsPresenter >> exportTimeoutField [ ^ exportTimeoutField ]
```

- [ ] **Step 4: Lint, import, run tests**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbSettingsPresenter.class.st \
        src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st
git commit -m "feat: add integer timeout fields to AbSettingsPresenter"
```

---

### Task 3: Drop lists for option symbols

`aiPermissionTimeoutOption` and `exportApprovalTimeoutOption` each choose from `AbConstants defaultApprovalOptions`.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbSettingsPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st`

- [ ] **Step 1: Add failing tests**

```smalltalk
{ #category : 'tests' }
AbSettingsPresenterTest >> testAiTimeoutOptionDropListShowsDefaultSelection [
	self
		assert: presenter aiTimeoutOptionDropList selectedItem
		equals: (AbConstants defaultApprovalOptions
			detect: [ :assoc | assoc value = AbConstants rejectOnce ]) key
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testExportTimeoutOptionDropListShowsDefaultSelection [
	self
		assert: presenter exportTimeoutOptionDropList selectedItem
		equals: (AbConstants defaultApprovalOptions
			detect: [ :assoc | assoc value = AbConstants rejectOnce ]) key
]
```

- [ ] **Step 2: Import tests, confirm failure**

```
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```

- [ ] **Step 3: Add drop list instVars and helpers**

Add `aiTimeoutOptionDropList`, `exportTimeoutOptionDropList` to `#instVars`.

Add private helper:
```smalltalk
{ #category : 'private' }
AbSettingsPresenter >> approvalOptionLabels [
	^ AbConstants defaultApprovalOptions collect: [ :assoc | assoc key ]
]

{ #category : 'private' }
AbSettingsPresenter >> labelForOptionId: anOptionSymbol [
	^ (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc value = anOptionSymbol ]
		ifNone: [ AbConstants defaultApprovalOptions first ]) key
]
```

Update `initializePresenters` to add after existing fields:
```smalltalk
	aiTimeoutOptionDropList := self newDropList.
	aiTimeoutOptionDropList items: self approvalOptionLabels.
	aiTimeoutOptionDropList
		selectItem: (self labelForOptionId: self settings aiPermissionTimeoutOption).

	exportTimeoutOptionDropList := self newDropList.
	exportTimeoutOptionDropList items: self approvalOptionLabels.
	exportTimeoutOptionDropList
		selectItem: (self labelForOptionId: self settings exportApprovalTimeoutOption).
```

Add accessors:
```smalltalk
{ #category : 'accessing' }
AbSettingsPresenter >> aiTimeoutOptionDropList [ ^ aiTimeoutOptionDropList ]

{ #category : 'accessing' }
AbSettingsPresenter >> exportTimeoutOptionDropList [ ^ exportTimeoutOptionDropList ]
```

- [ ] **Step 4: Lint, import, run tests**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: 6 passed.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbSettingsPresenter.class.st \
        src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st
git commit -m "feat: add option drop lists to AbSettingsPresenter"
```

---

### Task 4: Checkbox and Save/Cancel actions

**Files:**
- Modify: `src/AgenticBrowser-UI/AbSettingsPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st`

- [ ] **Step 1: Add failing tests**

```smalltalk
{ #category : 'tests' }
AbSettingsPresenterTest >> testUseDefaultMcpServersCheckboxShowsDefaultValue [
	self assert: presenter useDefaultMcpServersCheckbox state equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesIntegerFieldsToSettings [
	| s |
	s := AbSettings new.
	presenter settings: s.
	presenter initializePresenters.
	presenter watcherThrottleField text: '5'.
	presenter aiTimeoutField text: '600'.
	presenter exportTimeoutField text: '60'.
	presenter saveSettings.
	self assert: s watcherMessageThrottleSeconds equals: 5.
	self assert: s aiPermissionWaitTimeoutSeconds equals: 600.
	self assert: s exportApprovalWaitTimeoutSeconds equals: 60
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesOptionDropListsToSettings [
	| s allowLabel |
	s := AbSettings new.
	presenter settings: s.
	presenter initializePresenters.
	allowLabel := (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc value = AbConstants allowAlways ]) key.
	presenter aiTimeoutOptionDropList selectItem: allowLabel.
	presenter exportTimeoutOptionDropList selectItem: allowLabel.
	presenter saveSettings.
	self assert: s aiPermissionTimeoutOption equals: AbConstants allowAlways.
	self assert: s exportApprovalTimeoutOption equals: AbConstants allowAlways
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesBooleanCheckboxToSettings [
	| s |
	s := AbSettings new.
	presenter settings: s.
	presenter initializePresenters.
	presenter useDefaultMcpServersCheckbox state: false.
	presenter saveSettings.
	self assert: s useDefaultMcpServers equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testOnSaveActionCalledOnSave [
	| called |
	called := false.
	presenter onSaveAction: [ called := true ].
	presenter saveSettings.
	self assert: called
]
```

- [ ] **Step 2: Import tests, confirm failures**

```
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```

- [ ] **Step 3: Add checkbox, saveButton, cancelButton instVars and methods**

Add `useDefaultMcpServersCheckbox`, `saveButton`, `cancelButton` to `#instVars`.

Update `initializePresenters` (append):
```smalltalk
	useDefaultMcpServersCheckbox := self newCheckBox.
	useDefaultMcpServersCheckbox label: 'Use default MCP servers'.
	useDefaultMcpServersCheckbox state: self settings useDefaultMcpServers.

	saveButton := self newButton.
	saveButton label: 'Save'.
	saveButton action: [ self saveSettings. self window close ].

	cancelButton := self newButton.
	cancelButton label: 'Cancel'.
	cancelButton action: [ self window close ]
```

Add `saveSettings`:
```smalltalk
{ #category : 'actions' }
AbSettingsPresenter >> saveSettings [
	settings watcherMessageThrottleSeconds: watcherThrottleField text asInteger.
	settings aiPermissionWaitTimeoutSeconds: aiTimeoutField text asInteger.
	settings exportApprovalWaitTimeoutSeconds: exportTimeoutField text asInteger.
	settings aiPermissionTimeoutOption: (self optionIdForLabel: aiTimeoutOptionDropList selectedItem).
	settings exportApprovalTimeoutOption: (self optionIdForLabel: exportTimeoutOptionDropList selectedItem).
	settings useDefaultMcpServers: useDefaultMcpServersCheckbox state.
	saveAction value
]
```

Add private helper:
```smalltalk
{ #category : 'private' }
AbSettingsPresenter >> optionIdForLabel: aLabel [
	^ (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc key = aLabel ]
		ifNone: [ AbConstants defaultApprovalOptions first ]) value
]
```

Add accessors:
```smalltalk
{ #category : 'accessing' }
AbSettingsPresenter >> useDefaultMcpServersCheckbox [ ^ useDefaultMcpServersCheckbox ]

{ #category : 'accessing' }
AbSettingsPresenter >> saveButton [ ^ saveButton ]

{ #category : 'accessing' }
AbSettingsPresenter >> cancelButton [ ^ cancelButton ]
```

- [ ] **Step 4: Lint, import, run tests**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
/st-import AgenticBrowser-Tests /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: 11 passed.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-UI/AbSettingsPresenter.class.st \
        src/AgenticBrowser-Tests/AbSettingsPresenterTest.class.st
git commit -m "feat: add checkbox and save/cancel actions to AbSettingsPresenter"
```

---

### Task 5: Layout

Wire all widgets into the visible form layout.

**Files:**
- Modify: `src/AgenticBrowser-UI/AbSettingsPresenter.class.st`

No new tests — layout is verified visually via `AbSettingsPresenter openOn: AbSettings default`.

- [ ] **Step 1: Implement defaultLayout**

```smalltalk
{ #category : 'layout' }
AbSettingsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		borderWidth: 10;
		spacing: 6;
		add: (self labeledRow: 'Watcher throttle (seconds):' field: watcherThrottleField);
		add: (self labeledRow: 'AI permission timeout (seconds):' field: aiTimeoutField);
		add: (self labeledRow: 'AI timeout option:' field: aiTimeoutOptionDropList);
		add: (self labeledRow: 'Export timeout (seconds):' field: exportTimeoutField);
		add: (self labeledRow: 'Export timeout option:' field: exportTimeoutOptionDropList);
		add: useDefaultMcpServersCheckbox withConstraints: [ :c | c height: 28 ];
		addLast: self actionButtonsLayout withConstraints: [ :c | c height: 34 ];
		yourself
]

{ #category : 'layout' }
AbSettingsPresenter >> labeledRow: aLabelString field: aPresenter [
	^ SpBoxLayout newLeftToRight
		spacing: 6;
		add: (self newLabel label: aLabelString)
			withConstraints: [ :c | c width: 220 ];
		add: aPresenter;
		yourself
]

{ #category : 'layout' }
AbSettingsPresenter >> actionButtonsLayout [
	^ SpBoxLayout newLeftToRight
		addLast: saveButton withConstraints: [ :c | c width: 80 ];
		addLast: cancelButton withConstraints: [ :c | c width: 80 ];
		yourself
]
```

- [ ] **Step 2: Open and visually verify**

```smalltalk
"/st-eval"
AbSettingsPresenter openOn: AbSettings default
```

Check that all fields are populated with current defaults. Close window.

- [ ] **Step 3: Lint, import, run tests**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
/st-test AbSettingsPresenterTest
```
Expected: 11 passed.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-UI/AbSettingsPresenter.class.st
git commit -m "feat: implement form layout for AbSettingsPresenter"
```

---

### Task 6: Wire into AbBrowserPresenter menu

**Files:**
- Modify: `src/AgenticBrowser-UI/AbBrowserPresenter.class.st`

No new automated tests — verified visually.

- [ ] **Step 1: Add initializeWindow menu**

Read current `AbBrowserPresenter >> initializeWindow:`. Add a "Settings…" menu item to open the settings presenter:

```smalltalk
{ #category : 'initialization' }
AbBrowserPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Agentic Browser';
		initialExtent: 900 @ 600.
	aWindowPresenter whenClosedDo: [ self onWindowClosed ].
	aWindowPresenter addMenuItemLabel: 'Settings…' action: [ self openSettings ]
]

{ #category : 'actions' }
AbBrowserPresenter >> openSettings [
	| presenter |
	presenter := AbSettingsPresenter new.
	presenter settings: AbSettings default.
	presenter onSaveAction: [ AbSettings save ].
	presenter open
]
```

- [ ] **Step 2: Lint, import, visual test**

```
/st-lint src/AgenticBrowser-UI
/st-import AgenticBrowser-UI /home/mumez/git/pharo-agentic-browser/src
```

Open the browser and verify the Settings menu item appears and the presenter opens correctly:
```smalltalk
"/st-eval"
AbBrowserPresenter open
```
Close the browser afterwards:
```smalltalk
AbBrowserPresenter allInstances do: [:e | e window close]
```

- [ ] **Step 3: Run full test suite**

```
/st-test AbSettingsPresenterTest
/st-test AbSettingsTest
```
Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add src/AgenticBrowser-UI/AbBrowserPresenter.class.st
git commit -m "feat: add Settings menu item to AbBrowserPresenter"
```
