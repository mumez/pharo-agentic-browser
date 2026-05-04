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
