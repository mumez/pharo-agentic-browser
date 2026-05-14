# MCP Server Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to specify MCP servers (via `mcp.json`) that are passed to the ACP agent on session start, with optional auto-merge of built-in Smalltalk MCP servers.

**Architecture:** A new `AbMcpServersLoader` class reads `mcp.json` from `defaultAgenticBrowserRootDirectory`, optionally merges default Smalltalk servers (controlled by `AbSettings >> useDefaultMcpServers`), and returns a Collection of `ACPMcpServer` objects. `AbTopicSession >> sessionResultFromInitializeResponse:` calls `params mcpServers:` with this collection for all three session param types (new/resume/load), which all inherit from `ACPSessionParams`. The `addMcpServerBy:` builder method on `ACPSessionParams` is available for constructing individual servers.

**Tech Stack:** Pharo Smalltalk, Tonel file format, STON (existing settings persistence), STONJSON (mcp.json parsing), ACPMcpServer / ACPEnvVariable (ACP-DataTypes), SUnit for tests.

### ACP API reference

`ACPSessionParams` (superclass of `ACPNewSessionParams`, `ACPResumeSessionParams`, `ACPLoadSessionParams`):
- `addMcpServerBy: aBlock` — creates `ACPMcpServer new`, passes it to `aBlock`, appends to mcpServers
- `mcpServers: anArray` — accepts an Array of `ACPMcpServer` objects (replaces entire list)
- `mcpServers` — returns current Array of `ACPMcpServer`

`ACPMcpServer` fields: `name:`, `command:`, `args:`, `type:`, `url:`, `env:` (Array of `ACPEnvVariable`), `headers:`
- `addEnvNamed: aName value: aValue` — convenience method to append one env var

`ACPEnvVariable` fields: `name:`, `value:`

---

## File Structure

**New files:**
- `src/AgenticBrowser-Core/AbMcpServersLoader.class.st` — reads mcp.json, merges defaults, returns `OrderedCollection of ACPMcpServer`
- `src/AgenticBrowser-Tests/AbMcpServersLoaderTest.class.st` — unit tests for loader

**Modified files:**
- `src/AgenticBrowser-Core/AbSettings.class.st` — add `useDefaultMcpServers` setting
- `src/AgenticBrowser-Core/AbTopicSession.class.st` — pass mcpServers in session params
- `src/AgenticBrowser-Tests/AbSettingsTest.class.st` — add `useDefaultMcpServers` tests
- `src/AgenticBrowser-Tests/AbTopicSessionTest.class.st` — add mcpServers tests

---

## Task 1: Add `useDefaultMcpServers` to AbSettings

**Files:**
- Modify: `src/AgenticBrowser-Core/AbSettings.class.st`
- Test: `src/AgenticBrowser-Tests/AbSettingsTest.class.st`

- [ ] **Step 1: Write failing tests for `useDefaultMcpServers`**

Add to `AbSettingsTest`:

```smalltalk
{ #category : 'tests' }
AbSettingsTest >> testUseDefaultMcpServersDefaultIsTrue [

	self assert: AbSettings default useDefaultMcpServers equals: true
]

{ #category : 'tests' }
AbSettingsTest >> testUseDefaultMcpServersSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings useDefaultMcpServers: false.
	self assert: settings useDefaultMcpServers equals: false
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use the st-test skill to run `AbSettingsTest`.
Expected: FAIL — `useDefaultMcpServers` does not exist yet.

- [ ] **Step 3: Add `useDefaultMcpServers` accessors to AbSettings**

In `AbSettings.class.st`, add in the `defaults` category:

```smalltalk
{ #category : 'defaults' }
AbSettings >> defaultUseDefaultMcpServers [

	^ true
]
```

Add in the `accessing` category:

```smalltalk
{ #category : 'accessing' }
AbSettings >> useDefaultMcpServers [

	^ self
		  at: #useDefaultMcpServers
		  ifAbsentPut: [ self defaultUseDefaultMcpServers ]
]

{ #category : 'accessing' }
AbSettings >> useDefaultMcpServers: aBoolean [

	self at: #useDefaultMcpServers put: aBoolean
]
```

- [ ] **Step 4: Import and run tests**

Use st-import to import `AgenticBrowser-Core`, then st-test to run `AbSettingsTest`.
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbSettings.class.st src/AgenticBrowser-Tests/AbSettingsTest.class.st
git commit -m "feat: add useDefaultMcpServers setting to AbSettings"
```

---

## Task 2: Implement AbMcpServersLoader

**Files:**
- Create: `src/AgenticBrowser-Core/AbMcpServersLoader.class.st`
- Create: `src/AgenticBrowser-Tests/AbMcpServersLoaderTest.class.st`

### Background: mcp.json format

The file lives at `defaultAgenticBrowserRootDirectory / 'mcp.json'`. Standard Cursor format:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "uvx",
      "args": ["my-server-package"],
      "env": {"KEY": "value"}
    }
  }
}
```

Parsed with `STONJSON fromString: aFileRef contents` → returns a `Dictionary`. The `'mcpServers'` value is a nested Dictionary of `serverName → configDict`.

### Merge strategy

Internal working uses a `Dictionary` keyed by server name for easy override:
1. Start with `defaultConfigDicts` (name → raw config dict) when `useDefaultMcpServers` is true
2. Overlay entries from `loadFromFile` (same format) — user config wins
3. Convert merged dict to `OrderedCollection of ACPMcpServer` at the end

### Default Smalltalk MCP servers (raw config dicts)

```
'smalltalk-interop' →
  command: 'uvx'
  args: #('--from' 'git+https://github.com/mumez/pharo-smalltalk-interop-mcp-server.git' 'pharo-smalltalk-interop-mcp-server')
  env: {'PHARO_SIS_PORT' → '8086'}

'smalltalk-validator' →
  command: 'uvx'
  args: #('--from' 'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main' 'smalltalk-validator-mcp-server')
```

- [ ] **Step 1: Write failing tests for AbMcpServersLoader**

Create `src/AgenticBrowser-Tests/AbMcpServersLoaderTest.class.st`:

```smalltalk
Class {
	#name : 'AbMcpServersLoaderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadFromMissingFileReturnsEmpty [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	result := loader loadFromFile.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadFromFileReturnsParsedConfigDict [

	| loader jsonString tmpFile result |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"my-server":{"command":"uvx","args":["pkg"]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	result := loader loadFromFile.
	self assert: (result includesKey: 'my-server').
	self assert: ((result at: 'my-server') at: 'command') equals: 'uvx'.
	tmpFile ensureDelete
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithoutFileAndDefaultsReturnsEmpty [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsReturnsMcpServerObjects [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result allSatisfy: [ :each | each isKindOf: ACPMcpServer ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsIncludesSmalltalkInterop [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result anySatisfy: [ :s | s name = 'smalltalk-interop' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithDefaultsIncludesSmalltalkValidator [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result anySatisfy: [ :s | s name = 'smalltalk-validator' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadWithoutDefaultsDoesNotIncludeSmalltalkInterop [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self deny: (result anySatisfy: [ :s | s name = 'smalltalk-interop' ])
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadUserServersTakePrecedenceOverDefaults [

	| loader jsonString tmpFile result interopServer |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"smalltalk-interop":{"command":"myuvx","args":[]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	loader useDefaultMcpServers: true.
	result := loader load.
	interopServer := result detect: [ :s | s name = 'smalltalk-interop' ].
	self assert: interopServer command equals: 'myuvx'.
	tmpFile ensureDelete
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadSmalltalkInteropHasEnvVar [

	| loader result interopServer |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	interopServer := result detect: [ :s | s name = 'smalltalk-interop' ].
	self assert: (interopServer env anySatisfy: [ :e |
		e name = 'PHARO_SIS_PORT' and: [ e value = '8086' ] ])
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use st-test to run `AbMcpServersLoaderTest`.
Expected: FAIL — `AbMcpServersLoader` does not exist yet.

- [ ] **Step 3: Implement AbMcpServersLoader**

Create `src/AgenticBrowser-Core/AbMcpServersLoader.class.st`:

```smalltalk
Class {
	#name : 'AbMcpServersLoader',
	#superclass : 'Object',
	#instVars : [
		'mcpJsonFile',
		'useDefaultMcpServers'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbMcpServersLoader class >> default [

	^ self new
		  mcpJsonFile: AbSettings defaultAgenticBrowserRootDirectory / 'mcp.json';
		  useDefaultMcpServers: AbSettings default useDefaultMcpServers;
		  yourself
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile [
	^ mcpJsonFile
]

{ #category : 'accessing' }
AbMcpServersLoader >> mcpJsonFile: aFileReference [
	mcpJsonFile := aFileReference
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers [
	^ useDefaultMcpServers ifNil: [ true ]
]

{ #category : 'accessing' }
AbMcpServersLoader >> useDefaultMcpServers: aBoolean [
	useDefaultMcpServers := aBoolean
]

{ #category : 'loading' }
AbMcpServersLoader >> load [

	| merged |
	merged := Dictionary new.
	self useDefaultMcpServers ifTrue: [
		merged addAllFrom: self defaultConfigDicts ].
	merged addAllFrom: self loadFromFile.
	^ merged keys
		  collect: [ :name | self mcpServerNamed: name fromConfig: (merged at: name) ]
		  as: OrderedCollection
]

{ #category : 'loading' }
AbMcpServersLoader >> loadFromFile [

	| json |
	(mcpJsonFile isNil or: [ mcpJsonFile exists not ]) ifTrue: [ ^ Dictionary new ].
	json := STONJSON fromString: mcpJsonFile contents.
	^ (json at: 'mcpServers' ifAbsent: [ ^ Dictionary new ]) asDictionary
]

{ #category : 'private' }
AbMcpServersLoader >> defaultConfigDicts [

	^ Dictionary new
		  at: 'smalltalk-interop'
		  put: (Dictionary new
				   at: 'command' put: 'uvx';
				   at: 'args'
				   put: #( '--from'
					   'git+https://github.com/mumez/pharo-smalltalk-interop-mcp-server.git'
					   'pharo-smalltalk-interop-mcp-server' );
				   at: 'env' put: (Dictionary new
						    at: 'PHARO_SIS_PORT' put: '8086';
						    yourself);
				   yourself);
		  at: 'smalltalk-validator'
		  put: (Dictionary new
				   at: 'command' put: 'uvx';
				   at: 'args'
				   put: #( '--from'
					   'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main'
					   'smalltalk-validator-mcp-server' );
				   yourself);
		  yourself
]

{ #category : 'private' }
AbMcpServersLoader >> mcpServerNamed: aName fromConfig: aConfigDict [

	| server |
	server := ACPMcpServer new.
	server name: aName.
	(aConfigDict at: 'command' ifAbsent: [ nil ]) ifNotNil: [ :v | server command: v ].
	(aConfigDict at: 'args' ifAbsent: [ nil ]) ifNotNil: [ :v | server args: v ].
	(aConfigDict at: 'type' ifAbsent: [ nil ]) ifNotNil: [ :v | server type: v ].
	(aConfigDict at: 'url' ifAbsent: [ nil ]) ifNotNil: [ :v | server url: v ].
	(aConfigDict at: 'env' ifAbsent: [ nil ]) ifNotNil: [ :envSource |
		envSource isDictionary
			ifTrue: [ envSource keysAndValuesDo: [ :k :v | server addEnvNamed: k value: v ] ]
			ifFalse: [ server env: envSource ] ].
	^ server
]
```

Note: `env` in mcp.json is a flat Dictionary (`{"KEY": "VALUE"}`), so `keysAndValuesDo:` maps each entry to `addEnvNamed:value:`. The `ifFalse:` branch handles the case where a user passes an already-structured array (forward compatibility).

- [ ] **Step 4: Import and run tests**

Use st-import to import `AgenticBrowser-Core` and `AgenticBrowser-Tests`, then st-test to run `AbMcpServersLoaderTest`.
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbMcpServersLoader.class.st src/AgenticBrowser-Tests/AbMcpServersLoaderTest.class.st
git commit -m "feat: add AbMcpServersLoader building ACPMcpServer objects from mcp.json"
```

---

## Task 3: Wire mcpServers into AbTopicSession

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicSession.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicSessionTest.class.st`

### How mcpServers are passed

`sessionResultFromInitializeResponse:` calls `newSessionBy:`, `resumeSessionBy:`, or `loadSessionBy:`. All three params classes inherit `mcpServers:` from `ACPSessionParams`, which accepts an Array of `ACPMcpServer`. We resolve the servers once per connect and pass them to whichever branch is taken.

- [ ] **Step 1: Write failing tests**

Add to `AbTopicSessionTest`:

```smalltalk
{ #category : 'tests' }
AbTopicSessionTest >> testResolvedMcpServersReturnsCollection [

	| topic session result |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	result := session resolvedMcpServers.
	self assert: result isCollection
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientPassesMcpServersToNewSession [

	| topic session newSessionResult mockClient capturedMcpServers |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	newSessionResult := self mockSessionResultWithId: 'session-new'.
	capturedMcpServers := nil.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :h | ].
	mockClient
		on: #agentCommand:arguments:
		with: '/usr/bin/env'
		with: topic agentArguments
		verify: [ ].
	mockClient on: #connect verify: [ ].
	mockClient
		on: #initializeBy:
		with: MockObject any
		verify: [ :unused | nil ].
	mockClient
		on: #newSessionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPNewSessionParams buildBy: aBlock.
			capturedMcpServers := params mcpServers.
			newSessionResult ].

	session doConnectWithClient: mockClient.

	self verify: mockClient.
	self assert: capturedMcpServers isCollection
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use st-test to run `AbTopicSessionTest`.
Expected: FAIL — `resolvedMcpServers` does not exist.

- [ ] **Step 3: Add `resolvedMcpServers` and update `sessionResultFromInitializeResponse:`**

In `AbTopicSession.class.st`, add in `private` category:

```smalltalk
{ #category : 'private' }
AbTopicSession >> resolvedMcpServers [

	^ AbMcpServersLoader default load
]
```

Replace `sessionResultFromInitializeResponse:` entirely:

```smalltalk
{ #category : 'private' }
AbTopicSession >> sessionResultFromInitializeResponse: initializeResponse [

	| existingSessionId workingDirectoryPath capabilities mcpServers |
	existingSessionId := self sessionId.
	workingDirectoryPath := self topic ensureWorkingDirectoryForConnection.
	mcpServers := self resolvedMcpServers.
	(existingSessionId notNil and: [ initializeResponse notNil ]) ifTrue: [
		capabilities := initializeResponse agentCapabilities.
		(capabilities notNil and: [ capabilities isResumeSupported ]) ifTrue: [
			^ self client resumeSessionBy: [ :params |
				  params
					  sessionId: existingSessionId;
					  cwd: workingDirectoryPath;
					  mcpServers: mcpServers ] ].
		(capabilities notNil and: [ capabilities isLoadSupported ]) ifTrue: [
			^ self client loadSessionBy: [ :params |
				  params
					  sessionId: existingSessionId;
					  cwd: workingDirectoryPath;
					  mcpServers: mcpServers ] ] ].
	^ self client newSessionBy: [ :params |
		  params
			  cwd: workingDirectoryPath;
			  mcpServers: mcpServers ]
]
```

- [ ] **Step 4: Import and run all tests**

Use st-import to import `AgenticBrowser-Core` and `AgenticBrowser-Tests`, then st-test to run the full `AgenticBrowser-Tests` package.
Expected: All tests pass including the previously passing session tests.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicSession.class.st src/AgenticBrowser-Tests/AbTopicSessionTest.class.st
git commit -m "feat: pass ACPMcpServer objects from mcp.json to ACP session params on connect"
```

---

## Task 4: Export packages

- [ ] **Step 1: Export all modified packages**

Use st-export to export: `AgenticBrowser-Core`, `AgenticBrowser-Tests`

- [ ] **Step 2: Verify exported files**

```bash
git diff --stat src/
```

Expected: changes in `AbSettings.class.st`, new `AbMcpServersLoader.class.st`, `AbTopicSession.class.st`, and test files.

- [ ] **Step 3: Commit exported changes**

```bash
git add src/AgenticBrowser-Core/ src/AgenticBrowser-Tests/
git commit -m "chore: export packages after MCP server support implementation"
```

---

## Self-Review

### Spec coverage

| Requirement | Task |
|---|---|
| `mcp.json` が `defaultAgenticBrowserRootDirectory` にあれば使う | Task 2 (`loadFromFile`) |
| `mcp.json` フォーマットはcursor標準 (`mcpServers` キー) | Task 2 |
| `useDefaultMcpServers: true` → smalltalk-interop + smalltalk-validator をマージ | Task 2 (`load` + `defaultConfigDicts`) |
| `useDefaultMcpServers: false` → マージしない | Task 2 (`testLoadWithoutDefaultsDoesNotIncludeSmalltalkInterop`) |
| ユーザ設定が defaults より優先 | Task 2 (`testLoadUserServersTakePrecedenceOverDefaults`) |
| ACPセッション全種 (new/resume/load) に mcpServers を渡す | Task 3 |
| `AbSettings >> useDefaultMcpServers` 永続化 | Task 1 (既存の `settingsDict` ベース永続化で自動対応) |

### Type consistency

- `AbMcpServersLoader >> loadFromFile` → `Dictionary` (server name → raw config dict) — internal only
- `AbMcpServersLoader >> defaultConfigDicts` → same `Dictionary` — internal only
- `AbMcpServersLoader >> load` → `OrderedCollection of ACPMcpServer`
- `AbTopicSession >> resolvedMcpServers` → same `OrderedCollection of ACPMcpServer`
- `params mcpServers:` → receives `OrderedCollection of ACPMcpServer` ✓

### Placeholder scan

No TBDs or vague steps present.
