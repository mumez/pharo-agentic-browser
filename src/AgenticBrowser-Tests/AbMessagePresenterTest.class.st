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

	presenter := AbMessagePresenter new.
	presenter initializePresenters
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForHuman [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter updateMessage: msg.
	self assert: (presenter senderLabelText includesSubstring: 'You')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForAI [

	| msg |
	msg := AbMessage sender: #ai text: 'Hi'.
	presenter updateMessage: msg.
	self assert: (presenter senderLabelText includesSubstring: 'AI')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testSenderLabelForSystem [

	| msg |
	msg := AbMessage sender: #system text: 'Cancelled.'.
	presenter updateMessage: msg.
	self assert: (presenter senderLabelText includesSubstring: 'System')
]

{ #category : 'tests' }
AbMessagePresenterTest >> testContentTextMatchesMessageText [

	| msg |
	msg := AbMessage sender: #human text: 'Hello world'.
	presenter updateMessage: msg.
	self assert: presenter contentTextString equals: 'Hello world'
]

{ #category : 'tests' }
AbMessagePresenterTest >> testMessageSetterOnlySetsMessage [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter message: msg.
	self assert: presenter message equals: msg
]

{ #category : 'tests' }
AbMessagePresenterTest >> testUpdateContentAfterAppend [

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	presenter updateMessage: msg.
	msg appendText: ' world'.
	presenter updateContent.
	self assert: presenter contentTextString equals: 'Hello world'
]

{ #category : 'tests' }
AbMessagePresenterTest >> testApprovalRequestLabel [

	| msg |
	msg := AbMessage approvalRequestText: 'Allow export?'.
	presenter updateMessage: msg.
	self assert: (presenter senderLabelText includesSubstring: 'AI')
]
