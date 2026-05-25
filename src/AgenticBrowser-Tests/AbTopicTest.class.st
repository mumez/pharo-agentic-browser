Class {
	#name : 'AbTopicTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicTest >> setUp [

	super setUp.

	AbSettings initialize
]

{ #category : 'tests' }
AbTopicTest >> testAddAiPermissionRequestAddsMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addAiPermissionRequest: 'May I delete files?'.
	self assert: topic messages size equals: 1.
	self assert: msg isAiPermission.
	self assert: msg isApprovalRequest
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkAppendsToExistingAiMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	topic addAiTextChunk: ' world'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last text equals: 'Hello world'
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkCreatesMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Hello'
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkDoesNotAppendToThinkMessage [

	| topic |
	topic := AbTopic new.
	topic addAiThoughtChunk: 'Thinking...'.
	topic addAiTextChunk: 'Response text'.
	self assert: topic messages size equals: 2.
	self assert: topic messages first text equals: 'Thinking...'.
	self assert: topic messages first isThink.
	self assert: topic messages second text equals: 'Response text'.
	self deny: topic messages second isThink
]

{ #category : 'tests' }
AbTopicTest >> testAddAiThoughtChunkCreatesThinkMessage [

	| topic |
	topic := AbTopic new.
	topic addAiThoughtChunk: 'Let me think...'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Let me think...'.
	self assert: topic messages last isThink
]

{ #category : 'tests' }
AbTopicTest >> testAddExportApprovalRequestAddsMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addExportApprovalRequest: 'Export package Foo?'.
	self assert: topic messages size equals: 1.
	self assert: msg isExportApproval.
	self assert: msg isApprovalRequest
]

{ #category : 'tests' }
AbTopicTest >> testAvailableCommandsInitiallyEmpty [

	self assert: AbTopic new availableCommands isEmpty
]

{ #category : 'tests' }
AbTopicTest >> testCancelPromptCallsAcpCancelWithoutSystemMessage [

	| topic session mockClient |
	topic := AbTopic new.
	session := topic session.
	mockClient := MockObject new.
	mockClient
		on: #cancelBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPCancelParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1' ].
	session client: mockClient.
	session sessionId: 'session-1'.
	topic stateMachine handleEvent: #promptSent.

	topic cancelPrompt.

	self verify: mockClient.
	self assert: topic messages isEmpty.
	self assert: topic status equals: #endTurn
]

{ #category : 'tests' }
AbTopicTest >> testClearSessionIdDisconnectsAndClearsSessionId [

	| topic session mockClient |
	topic := AbTopic new.
	session := topic session.
	mockClient := MockObject new.
	mockClient on: #disconnect verify: [ ].
	session client: mockClient.
	session sessionId: 'session-1'.

	topic clearSessionId.

	self verify: mockClient.
	self assert: topic sessionId isNil.
	self assert: topic client isNil
]

{ #category : 'tests' }
AbTopicTest >> testCurrentModelInitiallyNil [

	self assert: AbTopic new currentModel isNil
]

{ #category : 'tests' }
AbTopicTest >> testDisconnectAbortsPendingAiPermission [

	| topic done option |
	topic := AbTopic new.
	done := Semaphore new.
	[
	option := topic requestPermission: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic disconnect.
	done waitTimeoutMilliseconds: 1000.
	self assert: option equals: #disconnected
]

{ #category : 'tests' }
AbTopicTest >> testDisconnectAbortsPendingExportApproval [

	| topic done option |
	topic := AbTopic new.
	done := Semaphore new.
	[
	option := topic requestPackageExport: 'Export package Foo?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic disconnect.
	done waitTimeoutMilliseconds: 1000.
	self assert: option equals: #disconnected
]

{ #category : 'tests' }
AbTopicTest >> testDisconnectKeepsSessionIdAndClearsTransientSessionData [

	| topic session mockClient options modelOption commands |
	topic := AbTopic new.
	session := topic session.
	mockClient := MockObject new.
	mockClient on: #disconnect verify: [ ].
	session client: mockClient.
	session sessionId: 'session-1'.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new
					  at: 'name' put: '/help';
					  at: 'description' put: 'Show help';
					  yourself)).
	topic updateAvailableCommands: commands.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'currentValue' put: 'claude-opus-4'.
	options := OrderedCollection with: modelOption.
	topic updateConfigOptions: options.

	topic disconnect.

	self verify: mockClient.
	self assert: topic sessionId equals: 'session-1'.
	self assert: topic availableCommands isEmpty.
	self assert: topic currentModel isNil
]

{ #category : 'tests' }
AbTopicTest >> testDoneToWorkingOnNewPrompt [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testEndedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic status equals: #endTurn
]

{ #category : 'tests' }
AbTopicTest >> testHasPendingApprovalRequest [

	| topic |
	topic := AbTopic new.
	self deny: topic hasPendingApprovalRequest.
	topic addAiPermissionRequest: 'Approve?'.
	self assert: topic hasPendingApprovalRequest
]

{ #category : 'tests' }
AbTopicTest >> testHasPendingApprovalRequestWithExportApproval [
	| topic |
	topic := AbTopic new.
	self deny: topic hasPendingApprovalRequest.
	topic addExportApprovalRequest: 'Export Foo?'.
	self assert: topic hasPendingApprovalRequest
]

{ #category : 'tests' }
AbTopicTest >> testHumanRespondedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	topic stateMachine handleEvent: #humanResponded.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testImportGuardNestingCounter [

	| topic workDir |
	topic := AbTopic new.
	workDir := topic workingDirectory.
	self deny: workDir isImportingFromSource.
	workDir beginImportFromSource.
	self assert: workDir isImportingFromSource.
	workDir beginImportFromSource.
	workDir endImportFromSource.
	self assert: workDir isImportingFromSource.
	workDir endImportFromSource.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbTopicTest >> testInitialStatus [

	self assert: AbTopic new status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testInitializeCreatesSessionWithBackReference [

	| topic |
	topic := AbTopic new.
	self assert: topic session topic equals: topic
]

{ #category : 'tests' }
AbTopicTest >> testLastUpdatedIsNilWhenNoMessages [

	self assert: AbTopic new lastUpdated isNil
]

{ #category : 'tests' }
AbTopicTest >> testLastUpdatedUsesNewestMessageUpdateTime [

	| topic firstMessage secondMessage |
	topic := AbTopic new.
	firstMessage := AbMessage sender: #ai text: 'First'.
	topic messages add: firstMessage.
	(Delay forMilliseconds: 1) wait.
	secondMessage := AbMessage sender: #ai text: 'Second'.
	topic messages add: secondMessage.
	(Delay forMilliseconds: 1) wait.
	firstMessage appendText: ' updated'.

	self assert: topic lastUpdated equals: firstMessage lastUpdated.
	self assert: topic lastUpdated > secondMessage lastUpdated
]

{ #category : 'tests' }
AbTopicTest >> testPendingAiPermissionMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addAiPermissionRequest: 'Approve AI action?'.
	self assert: topic pendingAiPermissionMessage equals: msg
]

{ #category : 'tests' }
AbTopicTest >> testPendingApprovalMessagePrefersAiPermission [

	| topic exportMsg permMsg |
	topic := AbTopic new.
	exportMsg := topic addExportApprovalRequest: 'Export Foo?'.
	permMsg := topic addAiPermissionRequest: 'Allow AI action?'.
	self assert: topic pendingApprovalMessage equals: permMsg
]

{ #category : 'tests' }
AbTopicTest >> testPendingExportApprovalMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addExportApprovalRequest: 'Export package Foo?'.
	self assert: topic pendingExportApprovalMessage equals: msg
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransitionFromDone [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransitionFromIdle [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testPromptSentTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testRequestPackageExportFromIdleReturnsResponse [

	| topic option done |
	topic := AbTopic new.
	done := Semaphore new.
	[
	option := topic requestPackageExport: 'Package ''Foo'' was modified. Export now?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	done waitTimeoutMilliseconds: 1000.
	self assert: option equals: AbConstants allowOnce.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testRequestPackageExportTimesOutAndRejects [

	| topic option done timedOut |
	topic := AbTopic new.
	AbSettings default exportApprovalWaitTimeoutSeconds: 0.
	done := Semaphore new.
	[
	option := topic requestPackageExport: 'Package ''Foo'' was modified. Export now?'.
	done signal ] fork.
	timedOut := done waitTimeoutMilliseconds: 200.
	self deny: timedOut.
	self assert: option equals: AbConstants rejectOnce.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testRequestPackageExportTimesOutUsingExportApprovalTimeoutOption [

	| topic option done timedOut |
	topic := AbTopic new.
	topic settings exportApprovalWaitTimeoutSeconds: 0.
	topic settings exportApprovalTimeoutOption: AbConstants allowAlways.
	done := Semaphore new.
	[
	option := topic requestPackageExport: 'Package ''Foo'' was modified. Export now?'.
	done signal ] fork.
	timedOut := done waitTimeoutMilliseconds: 200.
	self deny: timedOut.
	self assert: option equals: AbConstants allowAlways.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testRequestPermissionFromDoneTransitionsToWorking [

	| topic option done |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	done := Semaphore new.
	[
	option := topic requestPermission: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	done waitTimeoutMilliseconds: 1000.
	self assert: option equals: AbConstants allowOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testRequestPermissionReturnsResolvedResponse [

	| topic option done |
	topic := AbTopic new.
	done := Semaphore new.
	[
	option := topic requestPermission: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	done waitTimeoutMilliseconds: 1000.
	self assert: option equals: AbConstants allowOnce
]

{ #category : 'tests' }
AbTopicTest >> testRequestPermissionTimesOutUsingTopicSettings [

	| topic option done timedOut |
	topic := AbTopic new.
	topic settings aiPermissionWaitTimeoutSeconds: 0.
	done := Semaphore new.
	[
	option := topic requestPermission: 'Approve this action?'.
	done signal ] fork.
	timedOut := done waitTimeoutMilliseconds: 200.
	self deny: timedOut.
	self assert: option equals: AbConstants rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testRequestPermissionTimesOutUsingAiPermissionTimeoutOption [

	| topic option done timedOut |
	topic := AbTopic new.
	topic settings aiPermissionWaitTimeoutSeconds: 0.
	topic settings aiPermissionTimeoutOption: AbConstants allowAlways.
	done := Semaphore new.
	[
	option := topic requestPermission: 'Approve this action?'.
	done signal ] fork.
	timedOut := done waitTimeoutMilliseconds: 200.
	self deny: timedOut.
	self assert: option equals: AbConstants allowAlways.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalAllowAlways [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage aiPermissionRequestText: 'May I modify DBAdapter?'.
	topic messages add: msg.
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	self assert: msg approvalOption equals: AbConstants allowOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalRejectOnce [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage aiPermissionRequestText: 'May I delete files?'.
	topic messages add: msg.
	topic resolveApprovalWithOptionId: AbConstants rejectOnce.
	self assert: msg approvalOption equals: AbConstants rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalWhenNotWaitingForHumanDoesNotChangeState [

	| topic msg |
	topic := AbTopic new.
	msg := AbMessage aiPermissionRequestText: 'Export?'.
	topic messages add: msg.
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalWithOptionId [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage
		       aiPermissionRequestText: 'Choose an option'
		       options: {
				       'Allow once' -> AbConstants allowOnce.
				       'Deny' -> AbConstants rejectOnce }.
	topic messages add: msg.
	topic resolveApprovalWithOptionId: AbConstants allowOnce.
	self assert: msg approvalOption equals: AbConstants allowOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalWithOptionIdResolvesExportApproval [
	| topic msg |
	topic := AbTopic new.
	msg := topic addExportApprovalRequest: 'Export Foo?'.
	topic resolveApprovalWithOptionId: AbConstants rejectOnce.
	self assert: msg approvalOption equals: AbConstants rejectOnce.
	self assert: topic status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testSendPromptDelegatesToSendPromptWithResources [

	| topic |
	topic := AbTopic new.
	topic sendPrompt: 'hi'.
	self assert: topic messages size equals: 1.
	self assert: topic messages first text equals: 'hi'
]

{ #category : 'tests' }
AbTopicTest >> testSendPromptWithResourcesAddsHumanMessage [

	| topic |
	topic := AbTopic new.
	topic sendPrompt: 'hello' withResources: #().
	self assert: topic messages size equals: 1.
	self assert: topic messages first sender equals: #human.
	self assert: topic messages first text equals: 'hello'
]

{ #category : 'tests' }
AbTopicTest >> testStatusChangedAnnouncementFired [

	| topic statusChanges |
	topic := AbTopic new.
	statusChanges := OrderedCollection new.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | statusChanges add: ann topic status ]
		for: self.
	[ topic stateMachine handleEvent: #promptSent.
	self assert: (statusChanges includes: #working) ]
		ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicTest >> testStatusChangedAnnouncementUsesProvidedStatus [

	| topic announcedStatus |
	topic := AbTopic new.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | announcedStatus := ann status ]
		for: self.
	[ topic announceStatusChanged: #working.
	self assert: announcedStatus equals: #working ]
		ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicTest >> testStatusPredicates [

	| topic |
	topic := AbTopic new.
	self assert: topic isInitial.
	self deny: topic isWorking.

	topic stateMachine handleEvent: #promptSent.
	self deny: topic isInitial.
	self assert: topic isWorking.

	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic isWaitingForHuman.

	topic stateMachine handleEvent: #humanResponded.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic isEndTurn
]

{ #category : 'tests' }
AbTopicTest >> testUpdateAvailableCommandsFiresAnnouncement [

	| topic announced commands |
	topic := AbTopic new.
	announced := false.
	topic announcer
		when: AbTopicAvailableCommandsChanged
		do: [ :ann | announced := true ]
		for: self.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/help'; at: 'description' put: 'Show help'; yourself)).
	[ topic updateAvailableCommands: commands.
	self assert: announced ]
		ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicTest >> testUpdateAvailableCommandsStoresCommands [

	| topic commands |
	topic := AbTopic new.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/help'; at: 'description' put: 'Show help'; yourself))
		with: (ACPAvailableCommand new rawValues: (Dictionary new at: 'name' put: '/status'; at: 'description' put: 'Show status'; yourself)).
	topic updateAvailableCommands: commands.
	self assert: topic availableCommands size equals: 2
]

{ #category : 'tests' }
AbTopicTest >> testHandlePromptErrorAddsSystemMessage [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic handlePromptError: 'something went wrong'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: topic messages last text equals: 'something went wrong'
]

{ #category : 'tests' }
AbTopicTest >> testHandlePromptErrorTransitionsToEndTurn [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic handlePromptError: 'oops'.
	self assert: topic status equals: #endTurn
]

{ #category : 'tests' }
AbTopicTest >> testErrorInfoFromAcpErrorWithMessageTextOnly [

	| topic err info |
	topic := AbTopic new.
	err := ACPRequestError new rpcMessage: 'invalid session'.
	info := topic errorInfoFrom: err.
	self assert: info equals: 'invalid session'
]

{ #category : 'tests' }
AbTopicTest >> testErrorInfoFromAcpErrorWithCode [

	| topic err info |
	topic := AbTopic new.
	err := ACPRequestError code: -32600 message: 'bad request'.
	info := topic errorInfoFrom: err.
	self assert: info equals: 'bad request (code: -32600)'
]

{ #category : 'tests' }
AbTopicTest >> testErrorInfoFromAcpErrorWithCodeAndData [

	| topic err info |
	topic := AbTopic new.
	err := ACPRequestError code: -32600 message: 'bad request' data: 'extra detail'.
	info := topic errorInfoFrom: err.
	self assert: info equals: 'bad request (code: -32600) (data: ''extra detail'')'
]

{ #category : 'tests' }
AbTopicTest >> testDoExecutePromptHandlesNetworkError [

	| topic mockSession |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	mockSession := MockObject new.
	mockSession on: #ensureConnected verify: [ NetworkError signal: 'connection failed' ].
	topic session: mockSession.
	topic doExecutePrompt: 'hello' withResources: #().
	self assert: topic status equals: #endTurn.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system
]

{ #category : 'tests' }
AbTopicTest >> testDoExecutePromptHandlesAcpRequestError [

	| topic mockSession mockClient |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	mockClient := MockObject new.
	mockClient on: #promptBy: verify: [
		(ACPRequestError code: -32600 message: 'agent error') signal ].
	mockSession := MockObject new.
	mockSession on: #ensureConnected verify: [  ].
	mockSession on: #client verify: [ mockClient ].
	topic session: mockSession.
	topic doExecutePrompt: 'hello' withResources: #().
	self assert: topic status equals: #endTurn.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: (topic messages last text includesSubstring: 'agent error')
]

{ #category : 'tests' }
AbTopicTest >> testUpdateConfigOptionsExtractsModelCurrentValue [

	| topic options modelOption |
	topic := AbTopic new.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'currentValue' put: 'claude-opus-4'.
	options := OrderedCollection with: modelOption.
	topic updateConfigOptions: options.
	self assert: topic currentModel equals: 'claude-opus-4'
]

{ #category : 'tests' }
AbTopicTest >> testUpdateConfigOptionsFiresAnnouncement [

	| topic announced announcedModel options modelOption |
	topic := AbTopic new.
	announced := false.
	topic announcer
		when: AbTopicCurrentModelChanged
		do: [ :ann |
			announced := true.
			announcedModel := ann model ]
		for: self.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'currentValue' put: 'claude-sonnet-4'.
	options := OrderedCollection with: modelOption.
	[ topic updateConfigOptions: options.
	self assert: announced.
	self assert: announcedModel equals: 'claude-sonnet-4' ]
		ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicTest >> testUpdateConfigOptionsIgnoresNonModelCategory [

	| topic options modeOption |
	topic := AbTopic new.
	modeOption := ACPConfigOption new beModeCategory.
	modeOption rawValues at: 'currentValue' put: 'ask'.
	options := OrderedCollection with: modeOption.
	topic updateConfigOptions: options.
	self assert: topic currentModel isNil
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathLoadsSrcDirectoryFromProject [

	| topic dir |
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	(dir / '.project') writeStreamDo: [ :s |
		s nextPutAll: '{''srcDirectory'' : ''source''}' ].
	[
		topic := AbTopic new.
		topic workingDirectoryPath: dir fullName.
		self assert: topic workingDirectory srcDirectory equals: 'source'.
		self
			assert: topic workingDirectory sourcePath fullName
			equals: dir fullName , '/source' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathResetsWorkingDirectoryInstance [

	| topic firstWorkDir dir |
	topic := AbTopic new.
	firstWorkDir := topic workingDirectory.
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	(dir / '.project') writeStreamDo: [ :s |
		s nextPutAll: '{''srcDirectory'' : ''source''}' ].
	[
		topic workingDirectoryPath: dir fullName.
		self deny: topic workingDirectory == firstWorkDir.
		self assert: topic workingDirectory srcDirectory equals: 'source' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesDefaultSrcWhenProjectMissing [

	| topic dir |
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	[
		topic := AbTopic new.
		topic workingDirectoryPath: dir fullName.
		self assert: topic workingDirectory srcDirectory equals: 'src' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesGeneratedPathByDefault [

	| topic expectedPath |
	topic := AbTopic new title: 'ab-test-topic-name'.
	expectedPath := (Smalltalk imageDirectory / 'agentic-browser'
	                 / topic workingDirectory directoryName) fullName.
	self assert: topic workingDirectoryPath equals: expectedPath
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesProvidedPathWhenSet [

	| topic customPath |
	topic := AbTopic new.
	customPath := (FileLocator temp / ('ab-topic-custom-' , UUID new asString36))
		              fullName.
	topic workingDirectoryPath: customPath.
	self assert: topic workingDirectoryPath equals: customPath
]

{ #category : 'tests' }
AbTopicTest >> testSettingsReturnsCopyOfDefaultSettings [

	| topic |
	topic := AbTopic new.
	self deny: topic settings == AbSettings default.
	self
		assert: topic settings aiPermissionWaitTimeoutSeconds
		equals: AbSettings default aiPermissionWaitTimeoutSeconds.
	self
		assert: topic settings exportApprovalWaitTimeoutSeconds
		equals: AbSettings default exportApprovalWaitTimeoutSeconds.
	self
		assert: topic settings exportApprovalTimeoutOption
		equals: AbSettings default exportApprovalTimeoutOption.
	self
		assert: topic settings aiPermissionTimeoutOption
		equals: AbSettings default aiPermissionTimeoutOption
]
