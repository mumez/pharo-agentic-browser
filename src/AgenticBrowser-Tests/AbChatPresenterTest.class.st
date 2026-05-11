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
AbChatPresenterTest >> testCancelButtonClickEndsWorkingTurn [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	presenter onCancelButtonClicked.
	self assert: topic status equals: #endTurn.
	self assert: topic messages isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonDisabledInitially [

	self deny: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonDisabledWhenTopicEndTurn [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self deny: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonDisabledWhenTopicWaitingForHuman [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #waitingForHuman.
	self deny: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonEnabledWhenTopicWorking [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	self assert: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCommandSelectionInitInsertsSlashCommand [

	presenter commandNames: #( 'init' ).
	presenter commandsDropList selectItem: 'init'.
	self assert: presenter normalInputPresenter inputText equals: '/init '
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: approvalMessage approvalResponse equals: #allow_once.
	self assert: presenter normalInputPresenter sendButtonLabel equals: 'Send'.
	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmApprovalUsesSelectedOptionId [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic
		                   addAiPermissionRequest: 'Pick an option'
		                   options: {
						                   'Allow once' -> #allow_once.
						                   'Always allow' -> #allow_always }.
	presenter enterApprovalMode: approvalMessage.
	presenter confirmPresenter selectOptionNamed: 'Allow once'.
	presenter onConfirmButtonClicked.
	self assert: approvalMessage approvalResponse equals: #allow_once
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := AbTopic new.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeLoadsApprovalOptionsIntoConfirmPresenter [

	| approvalMessage |
	approvalMessage := AbMessage
		                   aiPermissionRequestText: 'Pick an option'
		                   options: {
						                   'Allow once' -> #allow_once.
						                   'Always allow' -> #allow_always }.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter confirmPresenter optionLabels asArray equals: #( 'Allow once' 'Always allow' )
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeSetsConfirmationText [

	| approvalMessage |
	approvalMessage := AbMessage aiPermissionRequestText: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter pendingApprovalMessage equals: approvalMessage
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeShowsConfirmPresenter [

	| approvalMessage |
	approvalMessage := AbMessage aiPermissionRequestText: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	self assert: presenter confirmPresenter denyButtonLabel equals: 'Deny'
]

{ #category : 'tests' }
AbChatPresenterTest >> testEnterApprovalModeSwitchesToConfirmPresenter [

	| approvalMessage |
	approvalMessage := AbMessage aiPermissionRequestText: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	self assert: presenter currentAnswerAreaPresenter equals: presenter confirmPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeRestoresNormalPresenter [

	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow package export?').
	presenter exitApprovalMode.
	self assert: presenter normalInputPresenter sendButtonLabel equals: 'Send'.
	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter normalInputPresenter inputPlaceholder equals: 'Type your request...'.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testExitApprovalModeSwitchesToNormalInputPresenter [

	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow?').
	presenter exitApprovalMode.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testInitialAnswerPresenterIsNormalInput [

	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelTextInitiallyEmpty [

	self assert: presenter modelText isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelTextShowsCurrentModelWhenTopicSet [

	| topic |
	topic := AbTopic new.
	topic session currentModel: 'claude-sonnet-4'.
	presenter topic: topic.
	self assert: presenter modelText equals: 'claude-sonnet-4'
]

{ #category : 'tests' }
AbChatPresenterTest >> testNextDotsTextCyclesFromEmpty [

	self assert: (presenter nextDotsTextAfter: '') equals: '.'
]

{ #category : 'tests' }
AbChatPresenterTest >> testNextDotsTextCyclesOneDot [

	self assert: (presenter nextDotsTextAfter: '.') equals: '..'
]

{ #category : 'tests' }
AbChatPresenterTest >> testNextDotsTextCyclesThreeDots [

	self assert: (presenter nextDotsTextAfter: '...') equals: ''
]

{ #category : 'tests' }
AbChatPresenterTest >> testNextDotsTextCyclesTwoDots [

	self assert: (presenter nextDotsTextAfter: '..') equals: '...'
]

{ #category : 'tests' }
AbChatPresenterTest >> testNormalInputHasCancelButton [

	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnAvailableCommandsChangedDoesNotInsertIntoInputImmediately [

	| topic commands |
	topic := AbTopic new.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'keep'.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/help'; at: 'description' put: 'Show help'; yourself)).
	presenter onAvailableCommandsChanged: topic commands: commands.
	self assert: presenter normalInputPresenter inputText equals: 'keep'
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnAvailableCommandsChangedUpdatesInput [

	| topic commands |
	topic := AbTopic new.
	presenter topic: topic.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/help'; at: 'description' put: 'Show help'; yourself))
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/status'; at: 'description' put: 'Show status'; yourself)).
	presenter onAvailableCommandsChanged: topic commands: commands.
	self assert: presenter commandNames size equals: 2
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnAvailableCommandsChangedWithEmptyListClearsCommands [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onAvailableCommandsChanged: topic commands: OrderedCollection new.
	self assert: presenter commandNames isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testOnMessageAddedApprovalRequestEntersApprovalMode [

	| msg |
	msg := AbMessage aiPermissionRequestText: 'Allow?'.
	presenter onMessageAdded: msg.
	self assert: presenter currentAnswerAreaPresenter equals: presenter confirmPresenter
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
AbChatPresenterTest >> testOnTopicCurrentModelChangedUpdatesModelText [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicCurrentModelChanged: topic model: 'claude-opus-4'.
	self assert: presenter modelText equals: 'claude-opus-4'
]

{ #category : 'tests' }
AbChatPresenterTest >> testStatusTextClearedWhenTopicEndTurn [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter statusText isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testStatusTextClearedWhenTopicWaitingForHuman [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #waitingForHuman.
	self assert: presenter statusText isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusDoneDoesNotExitApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusWorkingDoesNotExitApprovalMode [

	| topic |
	topic := AbTopic new.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #working.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicWhenAlreadyWorkingStartsDotsAnimation [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	self assert: presenter dotsAnimationProcess notNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicWhenAlreadyWorkingSyncsCancelButton [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	self assert: presenter normalInputPresenter isCancelEnabled
]

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
