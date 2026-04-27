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
