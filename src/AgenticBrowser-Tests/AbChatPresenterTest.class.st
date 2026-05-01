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
	presenter initializePresenters.
	presenter connectPresenters
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeShowsConfirmPresenter [

	| approvalMessage |
	approvalMessage := AbMessage approvalRequestText: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	self assert: presenter confirmPresenter denyButtonLabel equals: 'Deny'
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeSetsConfirmationText [

	| approvalMessage |
	approvalMessage := AbMessage approvalRequestText: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter pendingApprovalMessage equals: approvalMessage
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeRestoresNormalPresenter [

	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow package export?').
	presenter exitApprovalMode.
	self assert: presenter normalInputPresenter sendButtonLabel equals: 'Send'.
	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter normalInputPresenter inputPlaceholder equals: 'Type your request...'.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testNormalInputHasCancelButton [

	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusWorkingDoesNotExitApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #working.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusDoneDoesNotExitApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
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

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addApprovalRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: approvalMessage approvalResponse equals: #allowAlways.
	self assert: presenter normalInputPresenter sendButtonLabel equals: 'Send'.
	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addApprovalRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testInitialAnswerPresenterIsNormalInput [

	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeSwitchesToConfirmPresenter [

	| approvalMessage |
	approvalMessage := AbMessage approvalRequestText: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter currentAnswerAreaPresenter equals: presenter confirmPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeSwitchesToNormalInputPresenter [

	presenter enterApprovalMode: (AbMessage approvalRequestText: 'Allow?').
	presenter exitApprovalMode.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addApprovalRequest: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addApprovalRequest: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnMessageAddedUpdatesMessagesPresenterCount [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	presenter onMessageAdded: msg.
	self assert: presenter messagesPresenter messageCount equals: 1
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnMessageAddedWithAiMessageUpdatesCount [

	presenter onMessageAdded: (AbMessage sender: #human text: 'Hi').
	presenter onMessageAdded: (AbMessage sender: #ai text: 'Hello').
	self assert: presenter messagesPresenter messageCount equals: 2
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnMessageAddedApprovalRequestEntersApprovalMode [

	| msg |
	msg := AbMessage approvalRequestText: 'Allow?'.
	presenter onMessageAdded: msg.
	self assert: presenter currentAnswerAreaPresenter equals: presenter confirmPresenter
]
