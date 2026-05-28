# Screenshot Attachment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a screenshot button to the chat status bar that lets users capture a screen region, inserts a `@sc-yyyymmdd-nnn.png` mention into the input, and attaches the PNG to the prompt when sent.

**Architecture:** `AbScreenshotAttachment` manages capture/save/load; `AbScreenshotParser` extracts `@sc-` mentions from text; `AbChatPresenter` adds the button and wires the flow; `AbTopic >> trySendPrompt:withResources:` dispatches each resource via `resource applyToPromptParams: params` (double dispatch — no `isKindOf:` checks). `AbCodeMentionEmbedder` is refactored to return `AbCodeMentionResource` objects instead of raw `Association` so they participate in the same protocol.

**Mention format:** `@sc-yyyymmdd-nnn.png` (e.g. `@sc-20260527-001.png`). Lowercase prefix avoids collision with `AbCodeMentionParser` which only processes `@` followed by an uppercase letter.

**Tech Stack:** Pharo 13 Spec2 UI, PNGReadWriter, Screenshot (for region capture), ACPPromptParams (ACP library)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `src/AgenticBrowser-Core/AbScreenshotAttachment.class.st` | Create | Directory, name generation, PNG save/load, base64, `applyToPromptParams:` |
| `src/AgenticBrowser-Core/AbScreenshotParser.class.st` | Create | Parse `@sc-XXX.png` mentions from text |
| `src/AgenticBrowser-Core/AbCodeMentionResource.class.st` | Create | Wraps url+text; implements `applyToPromptParams:` for text resources |
| `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st` | Modify | Return `AbCodeMentionResource` instead of `Association` |
| `src/AgenticBrowser-Core/AbTopic.class.st` | Modify | Simplify `trySendPrompt:withResources:` to double-dispatch |
| `src/AgenticBrowser-UI/AbChatPresenter.class.st` | Modify | Add `screenshotButton` instVar, button in status bar, click handler, updated `onSendButtonClicked` |
| `src/AgenticBrowser-Tests/AbScreenshotAttachmentTest.class.st` | Create | Tests for name generation and PNG save/load |
| `src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st` | Create | Tests for mention parsing |
| `src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st` | Modify | Update expectations from `Association` to `AbCodeMentionResource` |
| `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st` | Modify | Tests for button and screenshot resource collection |
| `src/AgenticBrowser-Tests/AbTopicTest.class.st` | Modify | Test double-dispatch for both text and image resources |

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
	self assert: (name beginsWith: 'sc-20260527-').
	self assert: (name endsWith: '001')
]

{ #category : 'tests' }
AbScreenshotAttachmentTest >> testNextNameIncrementsSequence [

	| date a1 nextName |
	date := Date year: 2026 month: 5 day: 27.
	AbScreenshotAttachment screenshotDirectory ensureCreateDirectory.
	a1 := AbScreenshotAttachment saveForm: (Form extent: 2@2 depth: 32) forDate: date.
	nextName := AbScreenshotAttachment nextNameForDate: date.
	self assert: (nextName endsWith: '002').
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
	prefix := 'sc-' , dateString , '-'.
	existing := self screenshotDirectory exists
		ifTrue: [
			self screenshotDirectory fileNames
				select: [ :n | (n beginsWith: prefix) and: [ n endsWith: '.png' ] ] ]
		ifFalse: [ #() ].
	maxSeq := existing inject: 0 into: [ :max :each |
		| seqStr seq |
		seqStr := each copyFrom: prefix size + 1 to: each size - 4.
		seq := seqStr asInteger ifNil: [ 0 ].
		max max: seq ].
	^ prefix , ((maxSeq + 1) printString padded: #left to: 3 with: $0)
]

{ #category : 'factory' }
AbScreenshotAttachment class >> saveForm: aForm forDate: aDate [

	| attachmentName fileRef |
	self screenshotDirectory ensureCreateDirectory.
	attachmentName := self nextNameForDate: aDate.
	fileRef := self screenshotDirectory / (attachmentName , '.png').
	PNGReadWriter putForm: aForm onFileNamed: fileRef fullName.
	^ self new
		name: attachmentName;
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

{ #category : 'factory' }
AbScreenshotAttachment class >> captureAndSave [

	| form |
	form := Screenshot new formScreenshotFromUserSelection.
	form ifNil: [ ^ nil ].
	^ self saveForm: form forDate: Date today
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
AbScreenshotAttachment >> mentionString [

	^ '@' , name , '.png'
]

{ #category : 'accessing' }
AbScreenshotAttachment >> base64PngString [

	^ fileReference binaryReadStream contents base64Encoded
]

{ #category : 'prompt' }
AbScreenshotAttachment >> applyToPromptParams: params [

	params imagePrompt: self base64PngString mimeType: 'image/png'
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

## Task 2: AbScreenshotParser — parse @sc-XXX.png mentions from text

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
	result := AbScreenshotParser parseFrom: 'look at @sc-20260527-001.png please'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseMultiple [

	| result |
	result := AbScreenshotParser parseFrom: '@sc-20260527-001.png and @sc-20260527-002.png'.
	self assert: result size equals: 2.
	self assert: result first name equals: 'sc-20260527-001'.
	self assert: result last name equals: 'sc-20260527-002'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseIgnoresOtherMentions [

	| result |
	result := AbScreenshotParser parseFrom: '@SomeClass and @sc-20260527-001.png'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseAtEndOfString [

	| result |
	result := AbScreenshotParser parseFrom: 'see @sc-20260527-001.png'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
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
		stream next = $@ ifTrue: [
			(self tryParseFrom: stream) ifNotNil: [ :att | results add: att ] ] ].
	^ results
]

{ #category : 'private' }
AbScreenshotParser class >> tryParseFrom: stream [

	| saved token name |
	saved := stream position.
	token := String streamContents: [ :out |
		[ stream atEnd or: [ stream peek isSeparator ] ] whileFalse: [
			out nextPut: stream next ] ].
	((token beginsWith: 'sc-') and: [ token endsWith: '.png' ]) ifFalse: [
		stream position: saved.
		^ nil ].
	name := token copyFrom: 1 to: token size - 4.
	^ AbScreenshotAttachment named: name
]
```

- [ ] **Step 2.4: Import and run tests**

Use skill: `smalltalk-dev:st-import` then `smalltalk-dev:st-test` with `AbScreenshotParserTest`.
Expected: all 5 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbScreenshotParser.class.st src/AgenticBrowser-Tests/AbScreenshotParserTest.class.st
git commit -m "feat: add AbScreenshotParser to extract @sc- mentions from text"
```

---

## Task 3: AbCodeMentionResource — introduce resource protocol, refactor AbCodeMentionEmbedder

**Files:**
- Create: `src/AgenticBrowser-Core/AbCodeMentionResource.class.st`
- Modify: `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st`
- Modify: `src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st`

First, read the existing `AbCodeMentionEmbedderTest.class.st` to understand what assertions need updating.

- [ ] **Step 3.1: Write failing test for AbCodeMentionResource**

Add to `AbCodeMentionEmbedderTest` (or create a dedicated `AbCodeMentionResourceTest` if the file doesn't exist):

```smalltalk
{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testResourcesForReturnsAbCodeMentionResources [

	| mentions resources |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	self assert: resources size equals: 1.
	self assert: (resources first isKindOf: AbCodeMentionResource)
]
```

- [ ] **Step 3.2: Run test to confirm it fails**

Use skill: `smalltalk-dev:st-test` with the relevant test class.
Expected: `resources first` is an `Association`, not `AbCodeMentionResource`.

- [ ] **Step 3.3: Implement AbCodeMentionResource**

Create `src/AgenticBrowser-Core/AbCodeMentionResource.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMentionResource',
	#superclass : 'Object',
	#instVars : [
		'uri',
		'text'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'factory' }
AbCodeMentionResource class >> uri: aUriString text: aTextString [

	^ self new
		uri: aUriString;
		text: aTextString;
		yourself
]

{ #category : 'accessing' }
AbCodeMentionResource >> uri [

	^ uri
]

{ #category : 'accessing' }
AbCodeMentionResource >> uri: aString [

	uri := aString
]

{ #category : 'accessing' }
AbCodeMentionResource >> text [

	^ text
]

{ #category : 'accessing' }
AbCodeMentionResource >> text: aString [

	text := aString
]

{ #category : 'prompt' }
AbCodeMentionResource >> applyToPromptParams: params [

	params resourcePrompt: uri text: text
]
```

- [ ] **Step 3.4: Update AbCodeMentionEmbedder to return AbCodeMentionResource**

Read `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st` first, then replace the two private methods:

```smalltalk
{ #category : 'private' }
AbCodeMentionEmbedder class >> classResourceFor: mention [

	| className cls url tonel |
	className := mention className.
	cls := Smalltalk globals at: className asSymbol.
	url := '{1}/get-class-source?class_name={2}' format: { self mcpBaseUrl. className }.
	tonel := TonelWriter sourceCodeOf: cls.
	^ AbCodeMentionResource uri: url text: tonel
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> methodResourceFor: mention [

	| className methodName isClassSide cls url tonel |
	className := mention className.
	methodName := mention methodName.
	isClassSide := mention isClassSide.
	cls := Smalltalk globals at: className asSymbol.
	isClassSide ifTrue: [ cls := cls class ].
	url := '{1}/get-method-source?class_name={2}&method_name={3}&is_class_method={4}' format: { self mcpBaseUrl. className. methodName. isClassSide printString }.
	tonel := String streamContents: [ :str |
		TonelWriter new
			writeMethodDefinition: ((cls >> methodName asSymbol) asMCMethodDefinition)
			on: str ].
	^ AbCodeMentionResource uri: url text: tonel
]
```

- [ ] **Step 3.5: Update existing tests that assert on Association**

Read `AbCodeMentionEmbedderTest.class.st` and update any test that checks `resource key` or `resource value` (Association API) to use `resource uri` or `resource text` instead.

Example: if a test has:
```smalltalk
self assert: resources first key equals: '...'
```
Change to:
```smalltalk
self assert: resources first uri equals: '...'
```

- [ ] **Step 3.6: Import and run tests**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Core then AgenticBrowser-Tests) then `smalltalk-dev:st-test` with `AbCodeMentionEmbedderTest`.
Expected: all tests pass.

- [ ] **Step 3.7: Commit**

```bash
git add src/AgenticBrowser-Core/AbCodeMentionResource.class.st src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st
git commit -m "refactor: introduce AbCodeMentionResource with applyToPromptParams: protocol"
```

---

## Task 4: AbChatPresenter — screenshot button in status bar  <!-- was Task 3 -->

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

In `AbChatPresenter.class.st`, add `screenshotButton` to `instVars`:

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

Replace `initializeStatusBar`:

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

Add accessor (in `accessing` category):

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

## Task 5: AbChatPresenter — onScreenshotButtonClicked handler  <!-- was Task 4 -->

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`

The actual screen capture (`Screenshot new formScreenshotFromUserSelection`) requires user interaction and cannot be unit tested directly. The method delegates to `AbScreenshotAttachment captureAndSave` (already defined in Task 1) and inserts the mention via `insertMention:`.

- [ ] **Step 4.1: Add onScreenshotButtonClicked to AbChatPresenter**

Add in `event handling` category:

```smalltalk
{ #category : 'event handling' }
AbChatPresenter >> onScreenshotButtonClicked [

	| attachment |
	attachment := AbScreenshotAttachment captureAndSave.
	attachment ifNil: [ ^ self ].
	self normalInputPresenter insertMention: attachment mentionString
]
```

- [ ] **Step 4.2: Import and smoke test manually**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Core then AgenticBrowser-UI).

```smalltalk
AbBrowserPresenter open
```

Use `mcp__smalltalk-interop__read_screen` to verify the boxSelection icon button is visible to the right of the mode dropdown in the status bar.

Then close:
```smalltalk
AbBrowserPresenter allInstances do: [:e | e window close]
```

- [ ] **Step 4.3: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st
git commit -m "feat: implement screenshot capture button click handler"
```

---

## Task 6: AbChatPresenter — collect screenshot resources on send  <!-- was Task 5 -->

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st`
- Modify: `src/AgenticBrowser-Tests/AbMockTopicNoPromptSend.class.st`

- [ ] **Step 5.1: Write failing tests**

Add to `AbChatPresenterTest`:

```smalltalk
{ #category : 'tests' }
AbChatPresenterTest >> testSendWithScreenshotMentionAddsImageResource [

	| topic capturedResources form attachment |
	topic := self newMockTopic.
	presenter topic: topic.
	form := Form extent: 2@2 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	presenter normalInputPresenter inputField text: 'check this ' , attachment mentionString.
	capturedResources := nil.
	topic onSendBlock: [ :text :resources | capturedResources := resources ].
	presenter onSendButtonClicked.
	self assert: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ]).
	attachment fileReference delete
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendWithoutScreenshotMentionHasNoImageResource [

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

Read the existing `src/AgenticBrowser-Tests/AbMockTopicNoPromptSend.class.st` first, then add `sendBlock` instVar and these two methods without removing existing content:

```smalltalk
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

- [ ] **Step 5.2: Run tests to confirm they fail**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Tests) then `smalltalk-dev:st-test` with `AbChatPresenterTest`.
Expected: new tests fail with `doesNotUnderstand: #onSendBlock:`.

- [ ] **Step 5.3: Update onSendButtonClicked**

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
Expected: all tests pass.

- [ ] **Step 5.5: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st src/AgenticBrowser-Tests/AbChatPresenterTest.class.st src/AgenticBrowser-Tests/AbMockTopicNoPromptSend.class.st
git commit -m "feat: collect screenshot attachments from input text on send"
```

---

## Task 7: AbTopic — simplify trySendPrompt:withResources: via double dispatch  <!-- was Task 6 -->

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`

- [ ] **Step 7.1: Write failing tests**

Add to `AbTopicTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicTest >> testSendWithImageResourceCallsImagePrompt [

	| topic mockSession mockClient promptEntries form attachment |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	mockClient := MockObject new.
	mockClient
		on: #promptBy:
		verify: [ :block |
			| params |
			params := ACPPromptParams new.
			block value: params.
			promptEntries := params rawValues at: 'prompt' ifAbsent: [ #() ].
			ACPPromptResponse fromDictionary: { 'stopReason' -> 'end_turn' } asDictionary ].
	mockSession := MockObject new.
	mockSession on: #ensureConnected verify: [  ].
	mockSession on: #client verify: [ mockClient ].
	topic session: mockSession.
	form := Form extent: 2@2 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	topic doExecutePrompt: 'hello' withResources: (OrderedCollection with: attachment).
	self assert: (promptEntries anySatisfy: [ :entry |
		(entry at: 'type' ifAbsent: [ '' ]) = 'image' ]).
	attachment fileReference delete
]

{ #category : 'tests' }
AbTopicTest >> testSendWithTextResourceCallsResourcePrompt [

	| topic mockSession mockClient promptEntries resource |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	mockClient := MockObject new.
	mockClient
		on: #promptBy:
		verify: [ :block |
			| params |
			params := ACPPromptParams new.
			block value: params.
			promptEntries := params rawValues at: 'prompt' ifAbsent: [ #() ].
			ACPPromptResponse fromDictionary: { 'stopReason' -> 'end_turn' } asDictionary ].
	mockSession := MockObject new.
	mockSession on: #ensureConnected verify: [  ].
	mockSession on: #client verify: [ mockClient ].
	topic session: mockSession.
	resource := AbCodeMentionResource uri: 'http://example/foo' text: 'source'.
	topic doExecutePrompt: 'hello' withResources: (OrderedCollection with: resource).
	self assert: (promptEntries anySatisfy: [ :entry |
		(entry at: 'type' ifAbsent: [ '' ]) = 'resource' ]).
]
```

- [ ] **Step 7.2: Run tests to confirm they fail**

Use skill: `smalltalk-dev:st-test` with the two new tests.
Expected: both fail — `trySendPrompt:withResources:` still uses `isKindOf:` and `resource key`.

- [ ] **Step 7.3: Simplify trySendPrompt:withResources: to double dispatch**

Replace `trySendPrompt:withResources:` in `AbTopic.class.st`:

```smalltalk
{ #category : 'private' }
AbTopic >> trySendPrompt: aString withResources: aCollection [

	| result |
	self session ensureConnected.
	result := self client promptBy: [ :params |
		params sessionId: self sessionId.
		params textPrompt: aString.
		aCollection do: [ :resource | resource applyToPromptParams: params ] ].
	result stopReason = 'end_turn' ifTrue: [
		self checkGoalAchievement ifFalse: [
			self stateMachine handleEvent: #turnEnded ] ]
]
```

- [ ] **Step 7.4: Import and run all tests**

Use skill: `smalltalk-dev:st-import` (AgenticBrowser-Core) then `smalltalk-dev:st-test` with package `AgenticBrowser-Tests`.
Expected: all tests pass.

- [ ] **Step 7.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
git commit -m "refactor: simplify trySendPrompt:withResources: via applyToPromptParams: double dispatch"
```

---

## Task 8: End-to-end smoke test  <!-- was Task 7 -->

- [ ] **Step 7.1: Open browser and verify full flow**

```smalltalk
AbBrowserPresenter open
```

1. Select a topic with a working directory set
2. Click the boxSelection icon button in the status bar
3. Draw a rectangle to capture a screen region
4. Verify `@sc-yyyymmdd-nnn.png` appears in the input field
5. Edit the message text as desired and click Send
6. Verify the message appears in the message list
7. Verify the PNG file exists at `Smalltalk imageDirectory / 'agentic-browser' / 'screenshots'`

To verify deletion suppresses attachment:
1. Click screenshot button, draw region
2. Delete the `@sc-...png` token from the input
3. Send — no image resource should be attached

- [ ] **Step 7.2: Close browser**

```smalltalk
AbBrowserPresenter allInstances do: [:e | e window close]
```

---

## Task 9: Export packages  <!-- was Task 8 -->

- [ ] **Step 8.1: Export all modified packages**

Use skill: `smalltalk-dev:st-export` to export:
- `AgenticBrowser-Core`
- `AgenticBrowser-UI`
- `AgenticBrowser-Tests`

- [ ] **Step 8.2: Final commit**

```bash
git add src/
git commit -m "feat: screenshot attachment — capture, insert @sc- mention, send as image resource"
```
