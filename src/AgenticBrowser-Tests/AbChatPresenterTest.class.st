Class {
	#name : 'AbChatPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbChatPresenterTest >> setUp [

	presenter := AbChatPresenter new.
	presenter initializePresenters
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeUpdatesInputAndButton [

	| approvalMessage |
	approvalMessage := AbMessage approvalRequestText: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter sendButtonLabel equals: 'Confirm'.
	self
		assert: presenter inputPlaceholder
		equals: 'Respond to AI (yes / no / always)...'
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeRestoresInputAndButton [

	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow package export?').
	presenter exitApprovalMode.
	self assert: presenter sendButtonLabel equals: 'Send'.
	self assert: presenter inputPlaceholder equals: 'Type your request...'
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonExists [

	self assert: presenter cancelButtonLabel equals: 'Cancel'
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonClickAddsSystemMessage [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onCancelButtonClicked.
	self assert: (topic messages anySatisfy: [ :m |
			 m sender = #system and: [ m text includesSubstring: 'Cancelled' ] ])
]
