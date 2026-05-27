Class {
	#name : 'AbChatPresenterTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbChatPresenterTest >> setUp [

	super setUp.
	presenter := AbChatPresenter new.
	presenter initializePresenters.
	presenter connectPresenters
]

{ #category : 'running' }
AbChatPresenterTest >> tearDown [

	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonClickEndsWorkingTurn [

	| topic |
	topic := self newTopic.
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
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self deny: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonDisabledWhenTopicWaitingForHuman [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #waitingForHuman.
	self deny: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testCancelButtonEnabledWhenTopicWorking [

	| topic |
	topic := self newTopic.
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
AbChatPresenterTest >> testInputTextForCommandFormatsAsSlashCommand [

	self assert: (presenter inputTextForCommand: 'command1') equals: '/command1 '
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := self newTopic.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: approvalMessage approvalOption equals: AbConstants allowOnce.
	self assert: presenter normalInputPresenter sendButtonLabel equals: 'Send'.
	self assert: presenter normalInputPresenter cancelButtonLabel equals: 'Cancel'.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmApprovalUsesSelectedOptionId [

	| topic approvalMessage |
	topic := self newTopic.
	presenter topic: topic.
	approvalMessage := topic
		                   addAiPermissionRequest: 'Pick an option'
		                   options: {
						                   'Allow once' -> AbConstants allowOnce.
						                   'Always allow' -> AbConstants allowAlways }.
	presenter enterApprovalMode: approvalMessage.
	presenter confirmPresenter selectOptionNamed: 'Allow once'.
	presenter onConfirmButtonClicked.
	self assert: approvalMessage approvalOption equals: AbConstants allowOnce
]

{ #category : 'tests' }
AbChatPresenterTest >> testConfirmButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := self newTopic.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onConfirmButtonClicked.
	self assert: presenter currentAnswerAreaPresenter equals: presenter normalInputPresenter
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyApprovalExitsApprovalMode [

	| topic approvalMessage |
	topic := self newTopic.
	presenter topic: topic.
	approvalMessage := topic addAiPermissionRequest: 'Allow package export?'.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: presenter pendingApprovalMessage isNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyApprovalUsesSecondOptionInTwoItemMode [

	| topic approvalMessage |
	topic := self newTopic.
	presenter topic: topic.
	approvalMessage := topic
		                   addAiPermissionRequest: 'Pick an option'
		                   options: {
						                   'First option' -> #first_option.
						                   'Second option' -> #second_option }.
	presenter enterApprovalMode: approvalMessage.
	presenter onDenyButtonClicked.
	self assert: approvalMessage approvalOption equals: #second_option
]

{ #category : 'tests' }
AbChatPresenterTest >> testDenyButtonClickSwitchesToNormalInputPresenter [

	| topic approvalMessage |
	topic := self newTopic.
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
						                   'Allow once' -> AbConstants allowOnce.
						                   'Always allow' -> AbConstants allowAlways }.
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
AbChatPresenterTest >> testDropListsDisabledInitially [

	self deny: presenter commandsDropList isEnabled.
	self deny: presenter modelDropList isEnabled.
	self deny: presenter modeDropList isEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testDropListsDisabledWhenTopicWorking [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	self deny: presenter commandsDropList isEnabled.
	self deny: presenter modelDropList isEnabled.
	self deny: presenter modeDropList isEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testDropListsEnabledWhenTopicEndTurn [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter commandsDropList isEnabled.
	self assert: presenter modelDropList isEnabled.
	self assert: presenter modeDropList isEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelNamesInitiallyEmpty [

	self assert: presenter modelNames isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelNamesShowCurrentModelWhenTopicSet [

	| topic options |
	topic := self newTopic.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	presenter topic: topic.
	self assert: presenter modelNames asArray equals: #( 'claude-sonnet-4-6' 'claude-opus-4-7' ).
	self assert: presenter selectedModelName equals: 'claude-sonnet-4-6'
]

{ #category : 'tests' }
AbChatPresenterTest >> testSelectingModelCallsSetConfigOption [

	| topic session mockClient options result resultOptions |
	topic := self newTopic.
	session := topic session.
	session sessionId: 'session-1'.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	resultOptions := OrderedCollection
		                 with: (self modelOptionWithCurrentValue: 'claude-opus-4-7')
		                 with: (self modeOptionWithCurrentValue: 'ask').
	result := MockObject new.
	result on: #configOptions verify: [ resultOptions ].
	mockClient := MockObject new.
	mockClient
		on: #setSessionConfigOptionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPSetSessionConfigOptionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			self assert: params configId equals: 'model'.
			self assert: params value equals: 'claude-opus-4-7'.
			result ].
	session client: mockClient.
	presenter topic: topic.

	presenter modelDropList selectItem: 'claude-opus-4-7'.

	self verify: result.
	self verify: mockClient.
	self assert: presenter selectedModelName equals: 'claude-opus-4-7'
]

{ #category : 'tests' }
AbChatPresenterTest >> testModeNamesInitiallyEmpty [

	self assert: presenter modeNames isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testModeNamesShowsCurrentModeWhenTopicSet [

	| topic options |
	topic := self newTopic.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	presenter topic: topic.
	self assert: presenter modeNames asArray equals: #( 'Ask' 'Code' ).
	self assert: presenter selectedModeName equals: 'Ask'
]

{ #category : 'tests' }
AbChatPresenterTest >> testSelectingModeCallsSetConfigOption [

	| topic session mockClient options result resultOptions |
	topic := self newTopic.
	session := topic session.
	session sessionId: 'session-1'.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	resultOptions := OrderedCollection
		                 with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		                 with: (self modeOptionWithCurrentValue: 'code').
	result := MockObject new.
	result on: #configOptions verify: [ resultOptions ].
	mockClient := MockObject new.
	mockClient
		on: #setSessionConfigOptionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPSetSessionConfigOptionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			self assert: params configId equals: 'mode'.
			self assert: params value equals: 'code'.
			result ].
	session client: mockClient.
	presenter topic: topic.

	presenter modeDropList selectItem: 'Code'.

	self verify: result.
	self verify: mockClient.
	self assert: presenter selectedModeName equals: 'Code'
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
	topic := self newTopic.
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
	topic := self newTopic.
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
	topic := self newTopic.
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
AbChatPresenterTest >> testOnTopicCurrentModelChangedUpdatesModelDropList [

	| topic |
	topic := self newTopic.
	topic updateConfigOptions: (OrderedCollection with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')).
	presenter topic: topic.
	topic updateConfigOptions: (OrderedCollection with: (self modelOptionWithCurrentValue: 'claude-opus-4-7')).
	presenter onTopicCurrentModelChanged: topic.
	self assert: presenter selectedModelName equals: 'claude-opus-4-7'
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendButtonWithClassMentionAddsMessage [

	| topic |
	topic := self newMockTopic: 'classMention'.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'explain @OrderedCollection'.
	presenter onSendButtonClicked.
	self assert: topic messages size equals: 1.
	self assert: (topic messages first text includesSubstring: 'OrderedCollection')
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendButtonWithNoMentionsAddsMessage [

	| topic |
	topic := AbMockTopicNoPromptSend new title: 'ab-test-sendButtonWithNoMentions'.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'hello world'.
	presenter onSendButtonClicked.
	self assert: topic messages size equals: 1.
	self assert: topic messages first text equals: '/st-buddy hello world'
]

{ #category : 'tests' }
AbChatPresenterTest >> testStatusTextClearedWhenTopicEndTurn [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter statusText isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testStatusTextClearedWhenTopicWaitingForHuman [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter onTopicStatusChanged: topic status: #working.
	presenter onTopicStatusChanged: topic status: #waitingForHuman.
	self assert: presenter statusText isEmpty
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusDoneDoesNotExitApprovalMode [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #endTurn.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicStatusWorkingDoesNotExitApprovalMode [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	presenter enterApprovalMode: (AbMessage aiPermissionRequestText: 'Allow?').
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'.
	presenter onTopicStatusChanged: topic status: #working.
	self assert: presenter confirmPresenter confirmButtonLabel equals: 'Confirm'
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicWhenAlreadyWorkingStartsDotsAnimation [

	| topic |
	topic := self newTopic.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	self assert: presenter dotsAnimationProcess notNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testTopicWhenAlreadyWorkingSyncsCancelButton [

	| topic |
	topic := self newTopic.
	topic stateMachine handleEvent: #promptSent.
	presenter topic: topic.
	self assert: presenter normalInputPresenter isCancelEnabled
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelDropListShowsPlaceholderWhenTopicHasNoModelOption [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	self assert: presenter modelNames asArray equals: #( '- model -' ).
	self assert: presenter selectedModelName equals: '- model -'
]

{ #category : 'tests' }
AbChatPresenterTest >> testModeDropListShowsPlaceholderWhenTopicHasNoModeOption [

	| topic |
	topic := self newTopic.
	presenter topic: topic.
	self assert: presenter modeNames asArray equals: #( '- mode -' ).
	self assert: presenter selectedModeName equals: '- mode -'
]

{ #category : 'tests' }
AbChatPresenterTest >> testModelDropListRetainsSelectionWhenDisabled [

	| topic options |
	topic := self newTopic.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	presenter topic: topic.
	presenter updateDropListsEnabled: false.
	self assert: presenter selectedModelName equals: 'claude-sonnet-4-6'
]

{ #category : 'tests' }
AbChatPresenterTest >> testModeDropListRetainsSelectionWhenDisabled [

	| topic options |
	topic := self newTopic.
	options := OrderedCollection
		           with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')
		           with: (self modeOptionWithCurrentValue: 'ask').
	topic updateConfigOptions: options.
	presenter topic: topic.
	presenter updateDropListsEnabled: false.
	self assert: presenter selectedModeName equals: 'Ask'
]

{ #category : 'tests' }
AbChatPresenterTest >> testScreenshotButtonExistsInStatusBar [

	self assert: presenter screenshotButton isNotNil
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendWithScreenshotMentionAddsImageResource [

	| topic capturedResources form attachment |
	topic := self newMockTopic.
	presenter topic: topic.
	form := Form extent: 2@2 depth: 32.
	attachment := AbScreenshotAttachment saveForm: form forDate: (Date year: 2026 month: 5 day: 27).
	[ presenter normalInputPresenter inputField text: 'check this ' , attachment mentionString.
	  capturedResources := nil.
	  topic onSendBlock: [ :txt :res | capturedResources := res ].
	  presenter onSendButtonClicked.
	  self assert: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ]) ]
		ensure: [ attachment fileReference delete ]
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendWithoutScreenshotMentionHasNoImageResource [

	| topic capturedResources |
	topic := self newMockTopic.
	presenter topic: topic.
	presenter normalInputPresenter inputField text: 'just text'.
	capturedResources := nil.
	topic onSendBlock: [ :txt :res | capturedResources := res ].
	presenter onSendButtonClicked.
	self assert: capturedResources notNil description: 'sendPrompt:withResources: was never called'.
	self deny: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ])
]

{ #category : 'tests' }
AbChatPresenterTest >> testSendWithMissingFileScreenshotMentionHasNoImageResource [

	| topic capturedResources fakeName |
	topic := self newMockTopic.
	presenter topic: topic.
	fakeName := '@sc-19000101-999.png'.
	presenter normalInputPresenter inputField text: 'check this ' , fakeName.
	capturedResources := nil.
	topic onSendBlock: [ :txt :res | capturedResources := res ].
	presenter onSendButtonClicked.
	self assert: capturedResources notNil description: 'sendPrompt:withResources: was never called'.
	self deny: (capturedResources anySatisfy: [ :r | r isKindOf: AbScreenshotAttachment ])
]
