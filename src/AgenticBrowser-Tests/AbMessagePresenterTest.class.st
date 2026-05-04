Class {
	#name : 'AbMessagePresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbMessagePresenterTest >> setUp [

	presenter := AbMessagePresenter new
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForHuman [

	| msg microdown |
	msg := AbMessage sender: #human text: 'Hello'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## You')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForAI [

	| msg microdown |
	msg := AbMessage sender: #ai text: 'Hi'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## AI')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForSystem [

	| msg microdown |
	msg := AbMessage sender: #system text: 'Cancelled.'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## System')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testContentTextMatchesMessageText [

	| msg microdown |
	msg := AbMessage sender: #human text: 'Hello world'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testUpdateContentAfterAppend [

	| msg microdown |
	msg := AbMessage sender: #ai text: 'Hello'.
	msg appendText: ' world'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: 'Hello world')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testApprovalRequestLabel [

	| msg microdown |
	msg := AbMessage approvalRequestText: 'Allow export?'.
	microdown := presenter microdownTextFor: msg.
	self assert: (microdown includesSubstring: '## AI')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testRichTextForReturnsText [

	| msg rich |
	msg := AbMessage sender: #human text: 'Hello world'.
	rich := presenter richTextFor: msg.
	self assert: rich class equals: Text.
	self assert: (rich asString includesSubstring: 'You').
	self assert: (rich asString includesSubstring: 'Hello world')
]
