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

	| msg microdown |
	msg := AbMessage sender: #human text: 'Hello'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## You')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderLabelForAI [

	| msg microdown |
	msg := AbMessage sender: #ai text: 'Hi'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## AI')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testSenderLabelForSystem [

	| msg microdown |
	msg := AbMessage sender: #system text: 'Cancelled.'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## System')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testContentTextMatchesMessageText [

	| msg microdown |
	msg := AbMessage sender: #human text: 'Hello world'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testUpdateContentAfterAppend [

	| msg microdown |
	msg := AbMessage sender: #ai text: 'Hello'.
	msg appendText: ' world'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessageRichTextBuilderTest >> testApprovalRequestLabel [

	| msg microdown |
	msg := AbMessage approvalRequestText: 'Allow export?'.
	microdown := builder microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## AI')
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
