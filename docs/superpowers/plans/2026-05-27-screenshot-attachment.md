# Screenshot Attachment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a screenshot button to the chat status bar that lets users capture a screen region, inserts a `[Screenshot-yyyymmdd-nnn]` tag into the input, and attaches the PNG to the prompt when sent.

**Architecture:** `AbScreenshotAttachment` manages capture/save/load; `AbScreenshotParser` extracts tags from text; `AbChatPresenter` adds the button and wires the flow; `AbTopic >> trySendPrompt:withResources:` is extended to dispatch image resources via `ACPPromptParams >> imagePrompt:mimeType:`.

**Tech Stack:** Pharo 13 Spec2 UI, PNGReadWriter, Screenshot (for region capture), ACPPromptParams (ACP library)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `src/AgenticBrowser-Core/AbScreenshotAttachment.class.st` | Create | Directory, name generation, PNG save/load, base64 |
| `src/AgenticBrowser-Core/AbScreenshotParser.class.st` | Create | Parse `[Screenshot-XXX]` tags from text |
| `src/AgenticBrowser-Core/AbTopic.class.st` | Modify | Dispatch image vs text resources in `trySendPrompt:withResources:` |
| `src/AgenticBrowser-UI/AbChatPresenter.class.st` | Modify | Add `screenshotButton` instVar, button in status bar, click handler, updated `onSendButtonClicked` |
| `src/AgenticBrowser-Tests/AbScreenshotAttachmentTest.class.st` | Create | Tests for name generation and PNG save/load |
| `src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st` | Create | Tests for tag parsing |
| `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st` | Modify | Tests for button and screenshot resource collection |
| `src/AgenticBrowser-Tests/AbTopicTest.class.st` | Modify | Test that `imagePrompt:mimeType:` is called for `AbScreenshotAttachment` resources |

---

## Task 1: AbScreenshotAttachment — core class (name generation + PNG save/load)

**Files:**
- Create: `src/AgenticBrowser-Core/AbScreenshotAttachment.class.st`
- Create: `src/AgenticBrowser-Tests/AbScreenshotAttachmentTest.class.st`

- [ ] **Step 1.1: Write failing tests**

Create `src/AgenticBrowser-Tests/AbScreenshotAttachmentTest.class.st`:

```smalltalk
Class {
	#name : 'AbScreenshotAttachmentTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testNameFormat [

	| name |
	name := AbScreenshotAttachment nextNameForDate: (Date year: 2026 month: 5 day: 27).
	self assert: (name beginsWith: 'Screenshot-20260527-').
	self assert: (name endsWith: '001')
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testNextNameIncrementsSequence [

	| dir date a1 a2 |
	date := Date year: 2026 month: 5 day: 27.
	dir := AbScreenshotAttachment screenshotDirectory.
	dir ensureCreateDirectory.
	a1 := AbScreenshotAttachment saveForm: (Form extent: 2@2 depth: 32) forDate: date.
	a2 := AbScreenshotAttachment nextNameForDate: date.
	self assert: (a2 endsWith: '002').
	a1 fileReference delete
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testSaveFormCreatesFile [

	| form attachment |
	form := Form extent: 4@4 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	self assert: attachment fileReference exists.
	attachment fileReference delete
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testBase64PngStringIsNonEmpty [

	| form attachment |
	form := Form extent: 4@4 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	self assert: attachment base64PngString isString.
	self deny: attachment base64PngString isEmpty.
	attachment fileReference delete
]
```

- [ ] **Step 1.2: Run tests to confirm they fail**

Use skill: `smalltalk-dev:st-test` with class `AbScreenshotAttachmentTest`.
Expected: class not found error.

- [ ] **Step 1.3: Implement AbScreenshotAttachment**

Create `src/AgenticBrowser-Core/AbScreenshotAttachment.class.st`:

```smalltalk
Class {
	#name : 'AbScreenshotAttachment',
	#superclass : 'Object',
	#instVars : [
		'name',
		'fileReference'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbScreenshotAttachment class >> screenshotDirectory [

	^ AbSettings defaultAgenticBrowserRootDirectory / 'screenshots'
]

{ #category : 'accessing' }
AbScreenshotAttachment class >> nextNameForDate: aDate [

	| dateString prefix existing maxSeq |
	dateString := aDate year printString
		, (aDate month printString padded: #left to: 2 with: $0)
		, (aDate dayOfMonth printString padded: #left to: 2 with: $0).
	prefix := 'Screenshot-' , dateString , '-'.
	existing := self screenshotDirectory exists
		ifTrue: [
			self screenshotDirectory fileNames
				select: [ :n | (n beginsWith: prefix) and: [ n endsWith: '.png' ] ] ]
		ifFalse: [ #() ].
	maxSeq := existing inject: 0 into: [ :max :name |
		| seqStr seq |
		seqStr := name copyFrom: prefix size + 1 to: name size - 4.
		seq := seqStr asInteger ifNil: [ 0 ].
		max max: seq ].
	^ prefix , ((maxSeq + 1) printString padded: #left to: 3 with: $0)
]

{ #category : 'factory' }
AbScreenshotAttachment class >> saveForm: aForm forDate: aDate [

	| name fileRef |
	self screenshotDirectory ensureCreateDirectory.
	name := self nextNameForDate: aDate.
	fileRef := self screenshotDirectory / (name , '.png').
	PNGReadWriter putForm: aForm onFileNamed: fileRef fullName.
	^ self new
		name: name;
		fileReference: fileRef;
		yourself
]

{ #category : 'factory' }
AbScreenshotAttachment class >> named: aString [

	| fileRef |
	fileRef := self screenshotDirectory / (aString , '.png').
	^ self new
		name: aString;
		fileReference: fileRef;
		yourself
]

{ #category : 'accessing' }
AbScreenshotAttachment >> name [

	^ name
]

{ #category : 'accessing' }
AbScreenshotAttachment >> name: aString [

	name := aString
]

{ #category : 'accessing' }
AbScreenshotAttachment >> fileReference [

	^ fileReference
]

{ #category : 'accessing' }
AbScreenshotAttachment >> fileReference: aFileReference [

	fileReference := aFileReference
]

{ #category : 'accessing' }
AbScreenshotAttachment >> base64PngString [

	^ fileReference binaryReadStream contents base64Encoded
]
```

- [ ] **Step 1.4: Import and run tests**

Use skill: `smalltalk-dev:st-import` to import `AgenticBrowser-Core`, then `smalltalk-dev:st-test` with `AbScreenshotAttachmentTest`.
Expected: all 4 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbScreenshotAttachment.class.st src/AgenticBrowser-Tests/AbScreenshotAttachmentTest.class.st
git commit -m "feat: add AbScreenshotAttachment for PNG save/load and name generation"
```

---

## Task 2: AbScreenshotParser — parse [Screenshot-XXX] tags from text

**Files:**
- Create: `src/AgenticBrowser-Core/AbScreenshotParser.class.st`
- Create: `src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st`

- [ ] **Step 2.1: Write failing tests**

Create `src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st`:

```smalltalk
Class {
	#name : 'AbScreenshotParserTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbScreenshotParserTest >> testParseNone [

	| result |
	result := AbScreenshotParser parseFrom: 'hello world'.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseSingle [

	| result |
	result := AbScreenshotParser parseFrom: 'look at [Screenshot-20260527-001] please'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'Screenshot-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseMultiple [

	| result |
	result := AbScreenshotParser parseFrom: '[Screenshot-20260527-001] and [Screenshot-20260527-002]'.
	self assert: result size equals: 2.
	self assert: result first name equals: 'Screenshot-20260527-001'.
	self assert: result last name equals: 'Screenshot-20260527-002'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseIgnoresNonScreenshotBrackets [

	| result |
	result := AbScreenshotParser parseFrom: '[something-else] and [Screenshot-20260527-001]'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'Screenshot-20260527-001'
]
```

- [ ] **Step 2.2: Run tests to confirm they fail**

Use skill: `smalltalk-dev:st-test` with class `AbScreenshotParserTest`.
Expected: class not found error.

- [ ] **Step 2.3: Implement AbScreenshotParser**

Create `src/AgenticBrowser-Core/AbScreenshotParser.class.st`:

```smalltalk
Class {
	#name : 'AbScreenshotParser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'parsing' }
AbScreenshotParser class >> parseFrom: aString [

	| results stream |
	results := OrderedCollection new.
	stream := ReadStream on: aString.
	[ stream atEnd ] whileFalse: [
		(stream next = $[ and: [ stream peek notNil ]) ifTrue: [
			(self tryParseScreenshotFrom: stream) ifNotNil: [ :att | results add: att ] ] ].
	^ results
]

{ #category : 'private' }
AbScreenshotParser class >> tryParseScreenshotFrom: stream [

	| saved token |
	saved := stream position.
	token := String streamContents: [ :out |
		[ stream atEnd or: [ stream peek = $] ] ] whileFalse: [ out nextPut: stream next ] ].
	(stream atEnd not and: [ stream peek = $] ]) ifTrue: [ stream next ].
	(token beginsWith: 'Screenshot-') ifFalse: [
		stream position: saved.
		^ nil ].
	^ AbScreenshotAttachment named: token
]
```

- [ ] **Step 2.4: Import and run tests**

Use skill: `smalltalk-dev:st-import` then `smalltalk-dev:st-test` with `AbScreenshotParserTest`.
Expected: all 4 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbScreenshotParser.class.st src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st
git commit -m "feat: add AbScreenshotParser to extract screenshot tags from text"
```

---

## Task 3: AbChatPresenter — screenshot button in status bar

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st`

- [ ] **Step 3.1: Write failing test**

Add to `AbChatPresenterTest`:

```smalltalk
{ #category : 'tests' }
AbChatPresenterTest >> testScreenshotButtonExistsInStatusBar [

	self assert: presenter screenshotButton isNotNil
]
```

- [ ] **Step 3.2: Run test to confirm it fails**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Tests) then `smalltalk-dev:st-test` with `AbChatPresenterTest >> testScreenshotButtonExistsInStatusBar`.
Expected: `doesNotUnderstand: #screenshotButton`.

- [ ] **Step 3.3: Add screenshotButton instVar and update initializeStatusBar**

In `AbChatPresenter.class.st`, update the class definition to add `screenshotButton` to `instVars`:

```smalltalk
Class {
	#name : 'AbChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messagesPresenter',
		'normalInputPresenter',
		'confirmPresenter',
		'currentTopic',
		'pendingApprovalMessage',
		'logger',
		'dotsAnimationProcess',
		'statusBarPresenter',
		'statusLabel',
		'commandsDropList',
		'isRefreshingDropdownItems',
		'modelDropList',
		'modelConfigId',
		'modelOptions',
		'modeDropList',
		'modeOptions',
		'modeConfigId',
		'screenshotButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}
```

Replace `initializeStatusBar` (the method in the `initialization` category):

```smalltalk
{ #category : 'initialization' }
AbChatPresenter >> initializeStatusBar [

	(statusBarPresenter := self instantiate: SpPresenter)
		layout: (SpBoxLayout newLeftToRight
				 borderWidth: 2;
				 vAlignCenter;
				 add: (commandsDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 120 ];
				 add: (modelDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 220 ];
				 add: (modeDropList := statusBarPresenter newDropList)
				 withConstraints: [ :c | c width: 120 ];
				 add: (screenshotButton := statusBarPresenter newButton)
				 withConstraints: [ :c | c width: 28 ];
				 add: statusBarPresenter newNullPresenter;
				 addLast: (statusLabel := statusBarPresenter newLabel) expand: false;
				 yourself).
	screenshotButton
		icon: AbUiConstants boxSelection;
		action: [ self onScreenshotButtonClicked ]
]
```

Add accessor method (in `accessing` category):

```smalltalk
{ #category : 'accessing' }
AbChatPresenter >> screenshotButton [

	^ screenshotButton
]
```

- [ ] **Step 3.4: Import and run test**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-UI) then `smalltalk-dev:st-test` with `AbChatPresenterTest >> testScreenshotButtonExistsInStatusBar`.
Expected: PASS.

- [ ] **Step 3.5: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st src/AgenticBrowser-Tests/AbChatPresenterTest.class.st
git commit -m "feat: add screenshot button to chat status bar"
```

---

## Task 4: AbChatPresenter — onScreenshotButtonClicked handler

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`

The actual screen capture (`Screenshot new formScreenshotFromUserSelection`) requires user interaction and cannot be unit tested. The method delegates capture to `AbScreenshotAttachment captureAndSave` (added in step below), and the insertion uses existing `insertMention:`.

- [ ] **Step 4.1: Add captureAndSave to AbScreenshotAttachment**

Add to `AbScreenshotAttachment.class.st` (in `factory` category):

```smalltalk
{ #category : 'factory' }
AbScreenshotAttachment class >> captureAndSave [

	| form |
	form := Screenshot new formScreenshotFromUserSelection.
	form ifNil: [ ^ nil ].
	^ self saveForm: form forDate: Date today
]
```

- [ ] **Step 4.2: Add onScreenshotButtonClicked to AbChatPresenter**

Add in `event handling` category:

```smalltalk
{ #category : 'event handling' }
AbChatPresenter >> onScreenshotButtonClicked [

	| attachment |
	attachment := AbScreenshotAttachment captureAndSave.
	attachment ifNil: [ ^ self ].
	self normalInputPresenter insertMention: '[' , attachment name , ']'
]
```

- [ ] **Step 4.3: Import and smoke test manually**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Core then AgenticBrowser-UI).

Open the browser:
```smalltalk
AbBrowserPresenter open
```

Use skill: `smalltalk-dev:st-eval` to run `AbBrowserPresenter open`, then `smalltalk-dev:st-eval` to run `mcp__smalltalk-interop__read_screen` to verify the button appears in the status bar.
Expected: boxSelection icon button is visible to the right of the mode dropdown.

Then close:
```smalltalk
AbBrowserPresenter allInstances do: [:e | e window close]
```

- [ ] **Step 4.4: Commit**

```bash
git add src/AgenticBrowser-Core/AbScreenshotAttachment.class.st src/AgenticBrowser-UI/AbChatPresenter.class.st
git commit -m "feat: implement screenshot capture button click handler"
```

---

## Task 5: AbChatPresenter — collect screenshot resources on send

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st`

- [ ] **Step 5.1: Write failing test**

Add to `AbChatPresenterTest`:

```smalltalk
{ #category : 'tests' }
AbChatPresenterTest >> testSendWithScreenshotTagAddsImageResource [

	| topic capturedResources form attachment |
	topic := self newMockTopic.
	presenter topic: topic.
	form := Form extent: 2@2 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	presenter normalInputPresenter inputField
		text: 'check this [' , attachment name , ']'.
	capturedResources := nil.
	topic onSendBlock: [ :text :resources | capturedResources := resources ].
	presenter onSendButtonClicked.
	self assert: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ]).
	attachment fileReference delete
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendWithoutScreenshotTagHasNoImageResource [

	| topic capturedResources |
	topic := self newMockTopic.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'just text'.
	capturedResources := nil.
	topic onSendBlock: [ :text :resources | capturedResources := resources ].
	presenter onSendButtonClicked.
	self deny: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ])
]
```

Note: these tests require `AbMockTopicNoPromptSend` to support `onSendBlock:`. Add that support:

In `src/AgenticBrowser-Tests/AbMockTopicNoPromptSend.class.st`, add an `onSendBlock:` setter and override `sendPrompt:withResources:` to call it:

```smalltalk
Class {
	#name : 'AbMockTopicNoPromptSend',
	#superclass : 'AbTopic',
	#instVars : [
		'sendBlock'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'accessing' }
AbMockTopicNoPromptSend >> onSendBlock: aBlock [

	sendBlock := aBlock
]

{ #category : 'operations' }
AbMockTopicNoPromptSend >> sendPrompt: aString withResources: aCollection [

	sendBlock ifNotNil: [ sendBlock value: aString value: aCollection ].
	super sendPrompt: aString withResources: aCollection
]
```

(Read the existing `AbMockTopicNoPromptSend.class.st` first to ensure you add these methods without losing existing content.)

- [ ] **Step 5.2: Run tests to confirm they fail**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Tests) then `smalltalk-dev:st-test` with `AbChatPresenterTest`.
Expected: new tests fail with `doesNotUnderstand: #onSendBlock:`.

- [ ] **Step 5.3: Update onSendButtonClicked to collect screenshot resources**

Replace `onSendButtonClicked` in `AbChatPresenter.class.st`:

```smalltalk
{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText mentions resources screenshots |
	self currentTopic ifNil: [ ^ self ].
	text := self normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	self normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	mentions := AbCodeMentionParser parseFrom: text.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	screenshots := AbScreenshotParser parseFrom: text.
	screenshots do: [ :att | att fileReference exists ifTrue: [ resources add: att ] ].
	self currentTopic sendPrompt: promptText withResources: resources
]
```

- [ ] **Step 5.4: Import and run tests**

Use skill: `smalltalk-dev:st-import` (all packages) then `smalltalk-dev:st-test` with `AbChatPresenterTest`.
Expected: all tests including new ones pass.

- [ ] **Step 5.5: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st src/AgenticBrowser-Tests/AbChatPresenterTest.class.st src/AgenticBrowser-Tests/AbMockTopicNoPromptSend.class.st
git commit -m "feat: collect screenshot attachments from input text on send"
```

---

## Task 6: AbTopic — dispatch image resources via imagePrompt:mimeType:

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`

- [ ] **Step 6.1: Write failing test**

Add to `AbTopicTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicTest >> testSendWithImageResourceCallsImagePrompt [

	| topic mockSession mockClient imagePromptBase64 imagePromptMime form attachment |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	mockClient := MockObject new.
	mockClient
		on: #promptBy:
		verify: [ :block |
			| params |
			params := ACPPromptParams new.
			block value: params.
			imagePromptBase64 := params rawValues at: 'prompt' ifAbsent: [ #() ].
			ACPPromptResponse fromDictionary: { 'stopReason' -> 'end_turn' } asDictionary ].
	mockSession := MockObject new.
	mockSession on: #ensureConnected verify: [  ].
	mockSession on: #client verify: [ mockClient ].
	topic session: mockSession.
	form := Form extent: 2@2 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	topic doExecutePrompt: 'hello' withResources: (OrderedCollection with: attachment).
	self assert: (imagePromptBase64 anySatisfy: [ :entry |
		(entry at: 'type' ifAbsent: [ '' ]) = 'image' ]).
	attachment fileReference delete
]
```

- [ ] **Step 6.2: Run test to confirm it fails**

Use skill: `smalltalk-dev:st-test` with `AbTopicTest >> testSendWithImageResourceCallsImagePrompt`.
Expected: test fails because no image entry is in the prompt array (only text).

- [ ] **Step 6.3: Update trySendPrompt:withResources: to dispatch image resources**

Replace `trySendPrompt:withResources:` in `AbTopic.class.st`:

```smalltalk
{ #category : 'private' }
AbTopic >> trySendPrompt: aString withResources: aCollection [

	| result |
	self session ensureConnected.
	result := self client promptBy: [ :params |
		params sessionId: self sessionId.
		params textPrompt: aString.
		aCollection do: [ :resource |
			(resource isKindOf: AbScreenshotAttachment)
				ifTrue: [ params imagePrompt: resource base64PngString mimeType: 'image/png' ]
				ifFalse: [ params resourcePrompt: resource key text: resource value ] ] ].
	result stopReason = 'end_turn' ifTrue: [
		self checkGoalAchievement ifFalse: [
			self stateMachine handleEvent: #turnEnded ] ]
]
```

- [ ] **Step 6.4: Import and run all tests**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Core) then `smalltalk-dev:st-test` with package `AgenticBrowser-Tests`.
Expected: all tests pass including the new image resource test.

- [ ] **Step 6.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
git commit -m "feat: dispatch screenshot attachments as imagePrompt in ACP prompt params"
```

---

## Task 7: End-to-end smoke test

- [ ] **Step 7.1: Open browser and verify flow**

```smalltalk
AbBrowserPresenter open
```

1. Open browser, select a topic (or create one)
2. Click the boxSelection icon button in the status bar
3. Draw a rectangle to capture a region
4. Verify `[Screenshot-yyyymmdd-nnn]` appears in the input field
5. Edit the message text as desired
6. Click Send
7. Verify the message is sent (visible in message list)
8. Verify screenshot file exists at `Smalltalk imageDirectory / 'agentic-browser' / 'screenshots'`

To verify deletion removes the attachment:
1. Click screenshot button, draw region
2. Delete the `[Screenshot-...]` tag from the input
3. Send the message
4. Verify no image resource was included (check via `topic messages last text` — should not contain any screenshot reference)

- [ ] **Step 7.2: Close browser**

```smalltalk
AbBrowserPresenter allInstances do: [:e | e window close]
```

---

## Task 8: Export package

- [ ] **Step 8.1: Export all modified packages**

Use skill: `smalltalk-dev:st-export` to export:
- `AgenticBrowser-Core`
- `AgenticBrowser-UI`
- `AgenticBrowser-Tests`

- [ ] **Step 8.2: Final commit**

```bash
git add src/
git commit -m "feat: screenshot attachment — capture, insert tag, send as image resource"
```
