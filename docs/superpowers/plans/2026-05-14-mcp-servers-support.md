# MCP Server Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable users to specify MCP servers (via `mcp.json`) that are passed to the ACP agent on session start, with optional auto-merge of built-in Smalltalk MCP servers.

**Architecture:** A new `AbMcpServersLoader` class reads `mcp.json` from `defaultAgenticBrowserRootDirectory`, optionally merges default Smalltalk servers (controlled by `AbSettings >> useDefaultMcpServers`), and returns a Dictionary passed to `mcpServers:` on all three ACP session params (`ACPNewSessionParams`, `ACPResumeSessionParams`, `ACPLoadSessionParams`). The merge point is `AbTopicSession >> sessionResultFromInitializeResponse:`.

**Tech Stack:** Pharo Smalltalk, Tonel file format, STON (for existing settings), NativeJSON / Dictionary for mcp.json parsing, SUnit for tests.

---

## File Structure

**New files:**
- `src/AgenticBrowser-Core/AbMcpServersLoader.class.st` — reads mcp.json, merges default servers
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

In `AbSettings.class.st`, add two methods in the `accessing` category and one in `defaults`:

```smalltalk
{ #category : 'defaults' }
AbSettings >> defaultUseDefaultMcpServers [

	^ true
]

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

Use st-import skill to import `AgenticBrowser-Core`, then st-test to run `AbSettingsTest`.
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

The file is a JSON object at `defaultAgenticBrowserRootDirectory / 'mcp.json'`:

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

Parsing is done with `STONJSON >> fromString:` which returns a `Dictionary`. The `'mcpServers'` key holds a nested Dictionary of server name → config Dictionary.

### Default Smalltalk MCP servers

When `AbSettings default useDefaultMcpServers` is `true`, merge these two entries into the result:

```
'smalltalk-interop' →
  command: 'uvx'
  args: #('--from' 'git+https://github.com/mumez/pharo-smalltalk-interop-mcp-server.git' 'pharo-smalltalk-interop-mcp-server')
  env: { 'PHARO_SIS_PORT' → '8086' }

'smalltalk-validator' →
  command: 'uvx'
  args: #('--from' 'git+https://github.com/mumez/smalltalk-validator-mcp-server.git@main' 'smalltalk-validator-mcp-server')
```

Merge rule: mcp.json values win over defaults (user config takes precedence). Concretely: start with defaults, then overwrite with mcp.json entries.

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
AbMcpServersLoaderTest >> testLoadFromMissingFileReturnsEmptyDictionary [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	result := loader loadFromFile.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadFromFileReturnsServersDict [

	| loader jsonString tmpFile result |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"my-server":{"command":"uvx","args":["pkg"]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	result := loader loadFromFile.
	self assert: (result includesKey: 'my-server').
	self assert: (result at: 'my-server') isDictionary.
	tmpFile ensureDelete
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testDefaultMcpServersIncludesSmallTalkInterop [

	| loader defaults |
	loader := AbMcpServersLoader new.
	defaults := loader defaultMcpServers.
	self assert: (defaults includesKey: 'smalltalk-interop').
	self assert: ((defaults at: 'smalltalk-interop') at: 'command') equals: 'uvx'
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testDefaultMcpServersIncludesSmallTalkValidator [

	| loader defaults |
	loader := AbMcpServersLoader new.
	defaults := loader defaultMcpServers.
	self assert: (defaults includesKey: 'smalltalk-validator').
	self assert: ((defaults at: 'smalltalk-validator') at: 'command') equals: 'uvx'
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadMergesDefaultsWhenUseDefaultMcpServersTrue [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: true.
	result := loader load.
	self assert: (result includesKey: 'smalltalk-interop').
	self assert: (result includesKey: 'smalltalk-validator')
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadDoesNotMergeDefaultsWhenUseDefaultMcpServersFalse [

	| loader result |
	loader := AbMcpServersLoader new.
	loader mcpJsonFile: (FileReference / 'nonexistent' / 'mcp.json').
	loader useDefaultMcpServers: false.
	result := loader load.
	self deny: (result includesKey: 'smalltalk-interop').
	self deny: (result includesKey: 'smalltalk-validator')
]

{ #category : 'tests' }
AbMcpServersLoaderTest >> testLoadUserServersTakePrecedenceOverDefaults [

	| loader jsonString tmpFile result userConfig |
	loader := AbMcpServersLoader new.
	tmpFile := FileReference newTempFilePrefix: 'mcp' suffix: '.json'.
	jsonString := '{"mcpServers":{"smalltalk-interop":{"command":"myuvx","args":[]}}}'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: jsonString ].
	loader mcpJsonFile: tmpFile.
	loader useDefaultMcpServers: true.
	result := loader load.
	userConfig := result at: 'smalltalk-interop'.
	self assert: (userConfig at: 'command') equals: 'myuvx'.
	tmpFile ensureDelete
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use st-test skill to run `AbMcpServersLoaderTest`.
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

	| result |
	result := Dictionary new.
	self useDefaultMcpServers ifTrue: [
		result addAllFrom: self defaultMcpServers ].
	result addAllFrom: self loadFromFile.
	^ result
]

{ #category : 'loading' }
AbMcpServersLoader >> loadFromFile [

	| json |
	(mcpJsonFile isNil or: [ mcpJsonFile exists not ]) ifTrue: [ ^ Dictionary new ].
	json := STONJSON fromString: mcpJsonFile contents.
	^ (json at: 'mcpServers' ifAbsent: [ ^ Dictionary new ]) asDictionary
]

{ #category : 'defaults' }
AbMcpServersLoader >> defaultMcpServers [

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
```

- [ ] **Step 4: Import and run tests**

Use st-import to import `AgenticBrowser-Core` and `AgenticBrowser-Tests`, then st-test to run `AbMcpServersLoaderTest`.
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/AgenticBrowser-Core/AbMcpServersLoader.class.st src/AgenticBrowser-Tests/AbMcpServersLoaderTest.class.st
git commit -m "feat: add AbMcpServersLoader for reading mcp.json and merging default MCP servers"
```

---

## Task 3: Wire mcpServers into AbTopicSession

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopicSession.class.st`
- Test: `src/AgenticBrowser-Tests/AbTopicSessionTest.class.st`

### How mcpServers are passed

`sessionResultFromInitializeResponse:` calls `newSessionBy:`, `resumeSessionBy:`, or `loadSessionBy:`. Each block receives params that respond to `mcpServers:`. We call `params mcpServers: self resolvedMcpServers` in each block.

`resolvedMcpServers` delegates to `AbMcpServersLoader default load`.

- [ ] **Step 1: Write failing tests**

Add to `AbTopicSessionTest`:

```smalltalk
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
	self assert: capturedMcpServers isDictionary
]

{ #category : 'tests' }
AbTopicSessionTest >> testResolvedMcpServersReturnsDictionary [

	| topic session result |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	result := session resolvedMcpServers.
	self assert: result isDictionary
]
```

- [ ] **Step 2: Run tests to verify they fail**

Use st-test to run `AbTopicSessionTest`.
Expected: FAIL — `resolvedMcpServers` does not exist and mcpServers is not set.

- [ ] **Step 3: Add `resolvedMcpServers` and update `sessionResultFromInitializeResponse:`**

In `AbTopicSession.class.st`, add a new method in `private` category:

```smalltalk
{ #category : 'private' }
AbTopicSession >> resolvedMcpServers [

	^ AbMcpServersLoader default load
]
```

Update `sessionResultFromInitializeResponse:` to pass mcpServers in all three session param blocks:

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

- [ ] **Step 4: Update existing session tests that verify params**

The existing tests `testDoConnectWithClientUsesResumeWhenSessionIdExistsAndResumeSupported` and `testDoConnectWithClientFallsBackToLoadWhenResumeUnsupported` use `ACPResumeSessionParams buildBy:` and `ACPLoadSessionParams buildBy:` respectively. They don't currently assert on `mcpServers`, so they should still pass without changes. Verify they pass after import.

- [ ] **Step 5: Import and run all tests**

Use st-import to import `AgenticBrowser-Core` and `AgenticBrowser-Tests`, then st-test to run the full `AgenticBrowser-Tests` package.
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopicSession.class.st src/AgenticBrowser-Tests/AbTopicSessionTest.class.st
git commit -m "feat: pass mcpServers from mcp.json to ACP session params on connect"
```

---

## Task 4: Export packages

- [ ] **Step 1: Export all modified packages**

Use st-export skill to export:
- `AgenticBrowser-Core`
- `AgenticBrowser-Tests`

- [ ] **Step 2: Verify exported files**

```bash
git diff --stat src/
```

Expected: changes in `AbSettings.class.st`, `AbMcpServersLoader.class.st`, `AbTopicSession.class.st`, and test files.

- [ ] **Step 3: Commit exported changes**

```bash
git add src/AgenticBrowser-Core/ src/AgenticBrowser-Tests/
git commit -m "chore: export packages after MCP server support implementation"
```

---

## ACP Side Feedback

> **Note for ACP library maintainers:** `mcpServers:` currently accepts a raw `Dictionary` (server name → config Dictionary). A dedicated `ACPMcpServer` DataType class (similar to `ACPNewSessionParams` etc.) would improve type safety and discoverability. This would allow callers to write:
> ```smalltalk
> params mcpServers: { ACPMcpServer name: 'my-server' command: 'uvx' args: #('pkg') }
> ```
> instead of constructing nested Dictionaries manually.

---

## Self-Review

### Spec coverage

| Requirement | Task |
|---|---|
| `mcp.json` が `defaultAgenticBrowserRootDirectory` にあれば使う | Task 2 (`loadFromFile`) |
| `mcp.json` フォーマットはcursor標準 (`mcpServers` キー) | Task 2 |
| `useDefaultMcpServers: true` → smalltalk-interop + smalltalk-validator をマージ | Task 2 (`load` + `defaultMcpServers`) |
| `useDefaultMcpServers: false` → マージしない | Task 2 (tests: `testLoadDoesNotMergeDefaultsWhenUseDefaultMcpServersFalse`) |
| ユーザ設定が defaults より優先 | Task 2 (`testLoadUserServersTakePrecedenceOverDefaults`) |
| ACPセッション全種 (new/resume/load) に mcpServers を渡す | Task 3 |
| `AbSettings >> useDefaultMcpServers` 永続化 | Task 1 (既存の `settingsDict` ベース永続化で自動対応) |

### Type consistency

- `AbMcpServersLoader >> load` → `Dictionary` (server name → config Dictionary)
- `AbTopicSession >> resolvedMcpServers` → same `Dictionary`
- `params mcpServers:` → receives that `Dictionary`
- All consistent across tasks.

### Placeholder scan

No TBDs or vague steps present.
