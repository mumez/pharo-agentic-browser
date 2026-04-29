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
	self assert: presenter cancelButtonLabel equals: 'Deny'.
	self assert: presenter inputPlaceholder equals: ''
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeRestoresInputAndButton [

	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow package export?').
	presenter exitApprovalMode.
	self assert: presenter sendButtonLabel equals: 'Send'.
	self assert: presenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter inputPlaceholder equals: 'Type your request...'
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonExists [

	self assert: presenter cancelButtonLabel equals: 'Cancel'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusWorkingExitsApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow?').
	self assert: presenter sendButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #working.
	self assert: presenter sendButtonLabel equals: 'Send'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusDoneDoesNotExitApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow?').
	self assert: presenter sendButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #done.
	self assert: presenter sendButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonClickAddsSystemMessage [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	presenter onCancelButtonClicked.
	self assert: (topic messages anySatisfy: [ :m |
			 m sender = #system and: [ m text includesSubstring: 'Cancelled' ] ])
]
