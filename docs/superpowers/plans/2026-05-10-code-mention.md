# Code Mention Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to type `@ClassName` or `@ClassName >> methodName` in the chat input, which automatically embeds the referenced class/method Tonel source as an ACP resource when the message is sent.

**Architecture:** A parser (`AbCodeMentionParser`) scans raw input text for `@`-mention tokens and returns value objects (`AbCodeMention`). An embedder (`AbCodeMentionEmbedder`) resolves each mention to its Tonel source and a SIS server URL, producing URL→content associations. `AbChatPresenter` calls both, then passes resources to a new `AbTopic >> sendPrompt:withResources:` method that includes them in the ACP params block.

**Tech Stack:** Pharo 13, Spec2, ACP (ACPPromptParams), TonelWriter, MCClassDefinition, MCMethodDefinition, SUnit tests via AbTestCase.

---

## File Structure

**New files (create):**
| File | Class | Responsibility |
|------|-------|---------------|
| `src/AgenticBrowser-Core/AbCodeMention.class.st` | `AbCodeMention` | Value object: className, methodName (nil = class mention), isClassSide |
| `src/AgenticBrowser-Core/AbCodeMentionParser.class.st` | `AbCodeMentionParser` | Scan raw text → `OrderedCollection of AbCodeMention` |
| `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st` | `AbCodeMentionEmbedder` | Resolve mentions → `OrderedCollection of url→tonel Associations` |
| `src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st` | `AbCodeMentionParserTest` | Tests for all `@mention` patterns |
| `src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st` | `AbCodeMentionEmbedderTest` | Tests for Tonel generation + URL generation |

**Modified files:**
| File | What changes |
|------|-------------|
| `src/AgenticBrowser-Core/AbTopic.class.st` | Add `sendPrompt:withResources:`; make `sendPrompt:` delegate to it |
| `src/AgenticBrowser-UI/AbChatPresenter.class.st` | `onSendButtonClicked` parses mentions and calls `sendPrompt:withResources:` |

---

## Supported Mention Syntax

| Pattern | Example | Result |
|---------|---------|--------|
| `@ClassName` | `@OrderedCollection` | Class mention (instance side) |
| `@ClassName >> selector` | `@OrderedCollection >> add:` | Instance method |
| `@ClassName >> keyword:selector:` | `@OrderedCollection >> at:put:` | Multi-keyword method (no hash) |
| `@ClassName >> #selector` | `@OrderedCollection >> #add:` | Instance method (hash prefix OK) |
| `@ClassName >> #keyword:selector:` | `@OrderedCollection >> #at:put:` | Multi-keyword method (hash prefix OK) |
| `@ClassName class >> selector` | `@OrderedCollection class >> new` | Class-side method |
| `@ClassName class >> #selector` | `@OrderedCollection class >> #new` | Class-side method (hash prefix OK) |

---

## Task 1: AbCodeMention Value Object

**Files:**
- Create: `src/AgenticBrowser-Core/AbCodeMention.class.st`
- Create: `src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st` (shell only, tests in Task 2)

- [ ] **Step 1.1: Write the failing test class shell**

Create `src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMentionParserTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbCodeMentionParserTest >> testClassMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo'.
	self assert: mention className equals: 'Foo'.
	self assert: mention isClassMention.
	self deny: mention isMethodMention.
	self deny: mention isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testMethodMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo' methodName: 'bar' isClassSide: false.
	self assert: mention className equals: 'Foo'.
	self assert: mention methodName equals: 'bar'.
	self deny: mention isClassMention.
	self assert: mention isMethodMention.
	self deny: mention isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testClassSideMethodMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo' methodName: 'new' isClassSide: true.
	self assert: mention isClassSide
]
```

- [ ] **Step 1.2: Import the test file and run to confirm failure**

```
Use mcp__plugin_smalltalk-dev_smalltalk-interop__import_package with package_path pointing to src/AgenticBrowser-Tests
Then: mcp__plugin_smalltalk-dev_smalltalk-interop__run_class_test with class_name: 'AbCodeMentionParserTest'
```

Expected: Error — `AbCodeMention` does not exist yet.

- [ ] **Step 1.3: Create AbCodeMention**

Create `src/AgenticBrowser-Core/AbCodeMention.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMention',
	#superclass : 'Object',
	#instVars : [
		'className',
		'methodName',
		'isClassSide'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbCodeMention class >> className: aString [

	^ self new
		className: aString;
		methodName: nil;
		isClassSide: false;
		yourself
]

{ #category : 'instance creation' }
AbCodeMention class >> className: aString methodName: aMethod isClassSide: aBool [

	^ self new
		className: aString;
		methodName: aMethod;
		isClassSide: aBool;
		yourself
]

{ #category : 'accessing' }
AbCodeMention >> className [
	^ className
]

{ #category : 'accessing' }
AbCodeMention >> className: aString [
	className := aString
]

{ #category : 'accessing' }
AbCodeMention >> methodName [
	^ methodName
]

{ #category : 'accessing' }
AbCodeMention >> methodName: aString [
	methodName := aString
]

{ #category : 'accessing' }
AbCodeMention >> isClassSide [
	^ isClassSide
]

{ #category : 'accessing' }
AbCodeMention >> isClassSide: aBoolean [
	isClassSide := aBoolean
]

{ #category : 'testing' }
AbCodeMention >> isClassMention [
	^ methodName isNil
]

{ #category : 'testing' }
AbCodeMention >> isMethodMention [
	^ methodName notNil
]
```

- [ ] **Step 1.4: Import Core package and run tests**

```
Import src/AgenticBrowser-Core, then import src/AgenticBrowser-Tests
Run: AbCodeMentionParserTest
```

Expected: 3 tests pass.

- [ ] **Step 1.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbCodeMention.class.st src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st
git commit -m "feat: add AbCodeMention value object"
```

---

## Task 2: AbCodeMentionParser

**Files:**
- Create: `src/AgenticBrowser-Core/AbCodeMentionParser.class.st`
- Modify: `src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st` (add parsing tests)

- [ ] **Step 2.1: Add failing parser tests**

Add these methods to `src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'Check @OrderedCollection please'.
	self assert: mentions size equals: 1.
	self assert: mentions first className equals: 'OrderedCollection'.
	self assert: mentions first isClassMention
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesInstanceMethodMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'See @OrderedCollection >> add:'.
	self assert: mentions size equals: 1.
	self assert: mentions first className equals: 'OrderedCollection'.
	self assert: mentions first methodName equals: 'add:'.
	self deny: mentions first isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesMethodMentionWithHashPrefix [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> #add:'.
	self assert: mentions first methodName equals: 'add:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassSideMethodMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection class >> new'.
	self assert: mentions first isClassSide.
	self assert: mentions first methodName equals: 'new'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassSideMethodWithHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection class >> #new'.
	self assert: mentions first isClassSide.
	self assert: mentions first methodName equals: 'new'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesKeywordSelectorWithHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> #at:put:'.
	self assert: mentions first methodName equals: 'at:put:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesKeywordSelectorWithoutHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> at:put:'.
	self assert: mentions first methodName equals: 'at:put:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesMultipleMentions [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection and @Dictionary >> at:'.
	self assert: mentions size equals: 2.
	self assert: (mentions collect: #className) asArray equals: #('OrderedCollection' 'Dictionary')
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testIgnoresLowercaseMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@notAClass hello'.
	self assert: mentions isEmpty
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesEmptyString [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: ''.
	self assert: mentions isEmpty
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassMentionAtEndOfString [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'look at @OrderedCollection'.
	self assert: mentions size equals: 1.
	self assert: mentions first isClassMention
]
```

- [ ] **Step 2.2: Import tests, run, confirm failure**

Expected: `doesNotUnderstand: #parseFrom:` on `AbCodeMentionParser`.

- [ ] **Step 2.3: Create AbCodeMentionParser**

Create `src/AgenticBrowser-Core/AbCodeMentionParser.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMentionParser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'parsing' }
AbCodeMentionParser class >> parseFrom: aString [

	| mentions stream |
	mentions := OrderedCollection new.
	stream := ReadStream on: aString.
	[ stream atEnd ] whileFalse: [
		stream next = $@ ifTrue: [
			(self tryParseMentionFrom: stream)
				ifNotNil: [ :m | mentions add: m ] ] ].
	^ mentions
]

{ #category : 'private' }
AbCodeMentionParser class >> tryParseMentionFrom: stream [

	| className |
	className := self readIdentifierFrom: stream.
	(className notEmpty and: [ className first isUppercase ])
		ifFalse: [ ^ nil ].
	^ self tryParseRestFrom: stream forClass: className
]

{ #category : 'private' }
AbCodeMentionParser class >> tryParseRestFrom: stream forClass: className [

	| savedPos isClassSide methodName |
	savedPos := stream position.
	self skipSpacesFrom: stream.

	isClassSide := self trySkip: 'class' from: stream.
	isClassSide ifTrue: [ self skipSpacesFrom: stream ].

	(self trySkip: '>>' from: stream) ifFalse: [
		stream position: savedPos.
		^ AbCodeMention className: className ].

	self skipSpacesFrom: stream.
	stream peekFor: $#.
	methodName := self readSelectorFrom: stream.
	methodName ifEmpty: [ ^ AbCodeMention className: className ].
	^ AbCodeMention className: className methodName: methodName isClassSide: isClassSide
]

{ #category : 'private' }
AbCodeMentionParser class >> trySkip: aString from: stream [

	| saved |
	saved := stream position.
	aString do: [ :ch |
		(stream atEnd or: [ stream peek ~= ch ]) ifTrue: [
			stream position: saved.
			^ false ].
		stream next ].
	^ true
]

{ #category : 'private' }
AbCodeMentionParser class >> readIdentifierFrom: stream [

	^ String streamContents: [ :out |
		[ stream atEnd not
			and: [ stream peek isLetter or: [ stream peek isDigit ] ] ]
			whileTrue: [ out nextPut: stream next ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> readSelectorFrom: stream [

	^ String streamContents: [ :out |
		[ stream atEnd not
			and: [ stream peek isLetter or: [ stream peek isDigit
				or: [ stream peek = $: ] ] ] ]
			whileTrue: [ out nextPut: stream next ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> skipSpacesFrom: stream [

	[ stream atEnd not and: [ stream peek isSeparator ] ]
		whileTrue: [ stream next ]
]
```

- [ ] **Step 2.4: Import and run tests**

```
Import src/AgenticBrowser-Core, then src/AgenticBrowser-Tests
Run: AbCodeMentionParserTest
```

Expected: All 10 tests pass.

- [ ] **Step 2.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbCodeMentionParser.class.st src/AgenticBrowser-Tests/AbCodeMentionParserTest.class.st
git commit -m "feat: add AbCodeMentionParser for @class and @class>>method patterns"
```

---

## Task 3: AbCodeMentionEmbedder

**Files:**
- Create: `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st`
- Create: `src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st`

- [ ] **Step 3.1: Write failing tests**

Create `src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMentionEmbedderTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources size equals: 1.
	self assert: resources first key
		equals: 'http://localhost:8086/get-class-source?class_name=OrderedCollection'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceTonelContainsClassName [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first value includesSubstring: 'OrderedCollection')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first key
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=add:&is_class_method=false'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassSideMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'new' isClassSide: true.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first key
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=new&is_class_method=true'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceTonelContainsSelector [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first value includesSubstring: 'add:')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testUnknownClassIsSkipped [

	| mention resources |
	mention := AbCodeMention className: 'NonExistentClass99999'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources isEmpty
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testEmptyMentionsReturnsEmptyCollection [

	| resources |
	resources := AbCodeMentionEmbedder resourcesFor: #().
	self assert: resources isEmpty
]
```

- [ ] **Step 3.2: Import tests and confirm failure**

Expected: `doesNotUnderstand: #resourcesFor:` on `AbCodeMentionEmbedder`.

- [ ] **Step 3.3: Create AbCodeMentionEmbedder**

Create `src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st`:

```smalltalk
Class {
	#name : 'AbCodeMentionEmbedder',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'operations' }
AbCodeMentionEmbedder class >> resourcesFor: mentions [

	^ mentions inject: OrderedCollection new into: [ :acc :mention |
		[ acc add: (self resourceFor: mention) ]
			on: Error
			do: [ :e | "skip mentions that can't be resolved" ].
		acc ]
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> resourceFor: mention [

	^ mention isClassMention
		ifTrue: [ self classResourceFor: mention ]
		ifFalse: [ self methodResourceFor: mention ]
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> classResourceFor: mention [

	| className url tonel |
	className := mention className.
	url := 'http://localhost:8086/get-class-source?class_name=' , className.
	tonel := String streamContents: [ :str |
		| writer classDef |
		writer := TonelWriter new.
		classDef := (Smalltalk globals at: className asSymbol) asMCClassDefinition.
		writer writeClassDefinition: classDef on: str ].
	^ url -> tonel
]

{ #category : 'private' }
AbCodeMentionEmbedder class >> methodResourceFor: mention [

	| className methodName isClassSide cls url tonel |
	className := mention className.
	methodName := mention methodName.
	isClassSide := mention isClassSide.
	cls := Smalltalk globals at: className asSymbol.
	isClassSide ifTrue: [ cls := cls class ].
	url := 'http://localhost:8086/get-method-source?class_name=' , className
		, '&method_name=' , methodName
		, '&is_class_method=' , isClassSide printString.
	tonel := String streamContents: [ :str |
		| writer methodDef |
		writer := TonelWriter new.
		methodDef := (cls >> methodName asSymbol) asMCMethodDefinition.
		writer writeMethodDefinition: methodDef on: str ].
	^ url -> tonel
]
```

- [ ] **Step 3.4: Import and run tests**

```
Import src/AgenticBrowser-Core, then src/AgenticBrowser-Tests
Run: AbCodeMentionEmbedderTest
```

Expected: All 7 tests pass.

- [ ] **Step 3.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbCodeMentionEmbedder.class.st src/AgenticBrowser-Tests/AbCodeMentionEmbedderTest.class.st
git commit -m "feat: add AbCodeMentionEmbedder to resolve mentions to Tonel source + SIS URLs"
```

---

## Task 4: AbTopic sendPrompt:withResources:

**Files:**
- Modify: `src/AgenticBrowser-Core/AbTopic.class.st`
- Modify: `src/AgenticBrowser-Tests/AbTopicTest.class.st`

- [ ] **Step 4.1: Write failing test**

Add to `src/AgenticBrowser-Tests/AbTopicTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbTopicTest >> testSendPromptWithResourcesAddsHumanMessage [

	| topic |
	topic := AbTopic new.
	topic sendPrompt: 'hello' withResources: #().
	self assert: topic messages size equals: 1.
	self assert: topic messages first sender equals: #human.
	self assert: topic messages first text equals: 'hello'
]

{ #category : 'tests' }
AbTopicTest >> testSendPromptDelegatesToSendPromptWithResources [

	| topic |
	topic := AbTopic new.
	topic sendPrompt: 'hi'.
	self assert: topic messages size equals: 1.
	self assert: topic messages first text equals: 'hi'
]
```

- [ ] **Step 4.2: Import tests and confirm failure**

Expected: `doesNotUnderstand: #sendPrompt:withResources:`.

- [ ] **Step 4.3: Modify AbTopic**

In `src/AgenticBrowser-Core/AbTopic.class.st`, replace the existing `sendPrompt:` method and add the new one. The existing method at lines 553–569 reads:

```smalltalk
{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	| msg |
	msg := AbMessage sender: #human text: aString.
	self messages add: msg.
	self announceMessageAdded: msg.
	self stateMachine handleEvent: #promptSent.
	[
	| result |
	self ensureConnected.
		result := self client promptBy: [ :params |
				  params sessionId: self sessionId.
				  params textPrompt: aString ].
		result stopReason = 'end_turn' ifTrue: [
			self checkGoalAchievement ifFalse: [
				self stateMachine handleEvent: #turnEnded ] ] ] fork
]
```

Replace with these two methods:

```smalltalk
{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	self sendPrompt: aString withResources: #()
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString withResources: aCollection [

	| msg |
	msg := AbMessage sender: #human text: aString.
	self messages add: msg.
	self announceMessageAdded: msg.
	self stateMachine handleEvent: #promptSent.
	[
	| result |
	self ensureConnected.
		result := self client promptBy: [ :params |
				  params sessionId: self sessionId.
				  params textPrompt: aString.
				  aCollection do: [ :assoc |
				      params resourcePrompt: assoc key text: assoc value ] ].
		result stopReason = 'end_turn' ifTrue: [
			self checkGoalAchievement ifFalse: [
				self stateMachine handleEvent: #turnEnded ] ] ] fork
]
```

- [ ] **Step 4.4: Import and run tests**

```
Import src/AgenticBrowser-Core, then src/AgenticBrowser-Tests
Run: AbTopicTest
```

Expected: New tests pass; all prior AbTopicTest tests still pass.

- [ ] **Step 4.5: Commit**

```bash
git add src/AgenticBrowser-Core/AbTopic.class.st src/AgenticBrowser-Tests/AbTopicTest.class.st
git commit -m "feat: add AbTopic>>sendPrompt:withResources: to attach code resources to ACP prompt"
```

---

## Task 5: Wire into AbChatPresenter

**Files:**
- Modify: `src/AgenticBrowser-UI/AbChatPresenter.class.st`
- Modify: `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st`

- [ ] **Step 5.1: Write failing integration test**

Add to `src/AgenticBrowser-Tests/AbChatPresenterTest.class.st`:

```smalltalk
{ #category : 'tests' }
AbChatPresenterTest >> testSendButtonWithNoMentionsAddsMessage [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'hello world'.
	presenter onSendButtonClicked.
	self assert: topic messages size equals: 1.
	self assert: topic messages first text equals: '/st-buddy hello world'
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendButtonWithClassMentionAddsMessage [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'explain @OrderedCollection'.
	presenter onSendButtonClicked.
	self assert: topic messages size equals: 1.
	self assert: (topic messages first text includesSubstring: 'OrderedCollection')
]
```

- [ ] **Step 5.2: Import tests and confirm first test fails**

The first test (`testSendButtonWithNoMentionsAddsMessage`) may already pass if `onSendButtonClicked` works. The second test exercises mention parsing. Confirm they compile and run (the send will fork and fail silently without a client, but the message creation is synchronous).

- [ ] **Step 5.3: Modify AbChatPresenter >> onSendButtonClicked**

In `src/AgenticBrowser-UI/AbChatPresenter.class.st`, the existing method at lines 293–304:

```smalltalk
{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText |
	self currentTopic ifNil: [ ^ self ].
	text := self normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	self normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	self currentTopic sendPrompt: promptText
]
```

Replace with:

```smalltalk
{ #category : 'event handling' }
AbChatPresenter >> onSendButtonClicked [

	| text promptText mentions resources |
	self currentTopic ifNil: [ ^ self ].
	text := self normalInputPresenter inputText trimmed.
	text ifEmpty: [ ^ self ].
	self normalInputPresenter clearInput.
	promptText := self isFirstMessageInTopic
		              ifTrue: [ '/st-buddy ' , text ]
		              ifFalse: [ text ].
	mentions := AbCodeMentionParser parseFrom: text.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	self currentTopic sendPrompt: promptText withResources: resources
]
```

- [ ] **Step 5.4: Import and run tests**

```
Import src/AgenticBrowser-UI, then src/AgenticBrowser-Tests
Run: AbChatPresenterTest
```

Expected: All AbChatPresenterTest tests pass including the two new ones.

- [ ] **Step 5.5: Run full test suite**

```
Run package test: AgenticBrowser-Tests
```

Expected: All tests pass. No regressions.

- [ ] **Step 5.6: Manual smoke test**

In the running Pharo image:

```smalltalk
AbBrowserPresenter open.
"In the UI: create or select a topic, type:
  '@OrderedCollection please explain this class'
and click Send. Check in the Transcript or debugger that the ACP request
includes the Tonel source for OrderedCollection."
```

Check via `read_screen` that the send completes without error.

- [ ] **Step 5.7: Commit**

```bash
git add src/AgenticBrowser-UI/AbChatPresenter.class.st src/AgenticBrowser-Tests/AbChatPresenterTest.class.st
git commit -m "feat: wire code mention parsing into chat send — embed class/method source as ACP resources"
```

---

## Self-Review

**Spec coverage check:**
- `@Foo` class mention → Task 2 (parser) + Task 3 (embedder) ✓
- `@Foo >> bar` instance method → Task 2 ✓
- `@Foo class >> bar` class-side method → Task 2 ✓
- `@Foo >> #bar` hash prefix → Task 2 ✓
- `@Foo >> #bar:baz:` keyword with hash → Task 2 (readSelectorFrom: handles colons) ✓
- Tonel source embedded → Task 3 ✓
- `ACPPromptParams resourcePrompt:text:` used → Task 4 ✓
- SIS server URLs for class and method → Task 3 ✓

**Placeholder scan:** No TBDs, no "handle edge cases" without code, all steps have actual content.

**Type consistency:** `AbCodeMention className: / methodName: / isClassSide:` used consistently across Tasks 1–5. `AbCodeMentionParser parseFrom:` and `AbCodeMentionEmbedder resourcesFor:` used consistently in Tasks 3–5. `sendPrompt:withResources:` signature `aString` + collection-of-Associations consistent between Task 4 definition and Task 5 usage.
