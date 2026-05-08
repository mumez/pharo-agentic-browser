Class {
	#name : 'AbMessageRichTextBuilderTest',
	#superclass : 'TestCase',
	#instVars : [
		'builder'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbMessageRichTextBuilderTest >> setUp [

	builder := AbMessageRichTextBuilder new
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderLabelForHuman [

	| msg rich |
	msg := AbMessage sender: #human text: 'Hello'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'You')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderLabelForAI [

	| msg rich |
	msg := AbMessage sender: #ai text: 'Hi'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'AI')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderLabelForSystem [

	| msg rich |
	msg := AbMessage sender: #system text: 'Cancelled.'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'System')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testContentTextMatchesMessageText [

	| msg rich |
	msg := AbMessage sender: #human text: 'Hello world'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testUpdateContentAfterAppend [

	| msg rich |
	msg := AbMessage sender: #ai text: 'Hello'.
	msg appendText: ' world'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testApprovalRequestLabel [

	| msg rich |
	msg := AbMessage approvalRequestText: 'Allow export?'.
	rich := builder richTextFor: msg.
	self assert: (rich asString includesSubstring: 'AI')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testRichTextForReturnsText [

	| msg rich |
	msg := AbMessage sender: #human text: 'Hello world'.
	rich := builder richTextFor: msg.
	self assert: rich class equals: Text.
	self assert: (rich asString includesSubstring: 'You').
	self assert: (rich asString includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderColorForHumanIsTextColor [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	self
		assert: (builder senderColorFor: msg)
		equals: Smalltalk ui theme textColor
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderColorForAIIsWarningTextColor [

	| msg |
	msg := AbMessage sender: #ai text: 'Hi'.
	self
		assert: (builder senderColorFor: msg)
		equals: Smalltalk ui theme warningTextColor
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderColorForAIThinkIsGhostTextColor [

	| msg |
	msg := AbMessage sender: #ai text: 'Thinking...' isThink: true.
	self
		assert: (builder senderColorFor: msg)
		equals: Smalltalk ui theme ghostTextColor
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testBodyColorForAIThinkIsGhostTextColor [

	| msg rich senderLen bodyColor |
	msg := AbMessage sender: #ai text: 'Thinking...' isThink: true.
	rich := builder richTextFor: msg.
	senderLen := (AbMessageRichTextBuilder senderLabelFor: msg) size.
	bodyColor := (rich attributesAt: senderLen + 4)
		             detect: [ :attr | attr isKindOf: TextColor ]
		             ifNone: [ nil ].
	self assert: bodyColor isNotNil.
	self assert: bodyColor color equals: Smalltalk ui theme ghostTextColor
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testBodyColorForNonThinkAIIsUncolored [

	| msg rich senderLen bodyColor |
	msg := AbMessage sender: #ai text: 'Hello'.
	rich := builder richTextFor: msg.
	senderLen := (AbMessageRichTextBuilder senderLabelFor: msg) size.
	bodyColor := (rich attributesAt: senderLen + 4)
		             detect: [ :attr | attr isKindOf: TextColor ]
		             ifNone: [ nil ].
	self assert: bodyColor isNil
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testBodyColorForApprovalRequestIsGhostTextColor [

	| msg rich senderLen bodyColor |
	msg := AbMessage
		       approvalRequestText: 'Permission requested'
		       options: { 'Allow once' -> #allowOnce }.
	rich := builder richTextFor: msg.
	senderLen := (AbMessageRichTextBuilder senderLabelFor: msg) size.
	bodyColor := (rich attributesAt: senderLen + 4)
		             detect: [ :attr | attr isKindOf: TextColor ]
		             ifNone: [ nil ].
	self assert: bodyColor isNotNil.
	self assert: bodyColor color equals: Smalltalk ui theme ghostTextColor
]
