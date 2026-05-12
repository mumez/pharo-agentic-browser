Class {
	#name : 'AbTopicSessionTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'private' }
AbTopicSessionTest >> mockInitializeResponseWithCapabilities: capabilities [

	| initializeResponse |
	initializeResponse := MockObject new.
	initializeResponse on: #agentCapabilities verify: [ capabilities ].
	^ initializeResponse
]

{ #category : 'private' }
AbTopicSessionTest >> mockSessionResultWithId: aSessionId [

	| sessionResult |
	sessionResult := MockObject new.
	sessionResult on: #sessionId verify: [ aSessionId ].
	sessionResult on: #configOptions verify: [ #() ].
	^ sessionResult
]

{ #category : 'tests' }
AbTopicSessionTest >> testOnCreatesSessionWithTopicBackReference [

	| topic session |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	self assert: session topic equals: topic
]

{ #category : 'tests' }
AbTopicSessionTest >> testOnInitializesTransientFields [

	| topic session |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	self assert: session sessionId isNil.
	self assert: session currentModel isNil.
	self assert: session availableCommands isEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testDisconnectClearsTransientFields [

	| topic session mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	mockClient := MockObject new.
	mockClient on: #disconnect verify: [ ].
	session client: mockClient.
	session sessionId: 'session-1'.
	session currentModel: 'claude-opus-4'.
	session availableCommands: (OrderedCollection
			 with: (ACPAvailableCommand new rawValues: (Dictionary new
					  at: 'name' put: '/help';
					  at: 'description' put: 'Show help';
					  yourself))).

	session disconnect.

	self verify: mockClient.
	self assert: session client isNil.
	self assert: session sessionId isNil.
	self assert: session currentModel isNil.
	self assert: session availableCommands isEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testAnnouncerDelegatesToTopicAnnouncer [

	| topic session |
	topic := AbTopic new.
	session := topic session.
	self assert: session announcer equals: topic announcer
]

{ #category : 'tests' }
AbTopicSessionTest >> testConnectResponsibilityMovedToSession [

	self assert: (AbTopicSession canUnderstand: #doConnect).
	self assert: (AbTopicSession canUnderstand: #ensureConnected).
	self deny: (AbTopic canUnderstand: #doConnect).
	self deny: (AbTopic canUnderstand: #ensureConnected)
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientFallsBackToLoadWhenResumeUnsupported [

	| topic session capabilities initializeResponse loadResult mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.
	capabilities := MockObject new.
	capabilities on: #isResumeSupported verify: [ false ].
	capabilities on: #isLoadSupported verify: [ true ].
	initializeResponse := self
		                      mockInitializeResponseWithCapabilities: capabilities.
	loadResult := self mockSessionResultWithId: 'session-1-loaded'.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :handler | ].
	mockClient
		on: #agentCommand:arguments:
		with: '/usr/bin/env'
		with: topic agentArguments
		verify: [ ].
	mockClient on: #connect verify: [ ].
	mockClient
		on: #initializeBy:
		with: MockObject any
		verify: [ :unused | initializeResponse ].
	mockClient
		on: #loadSessionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPLoadSessionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			loadResult ].

	session doConnectWithClient: mockClient.

	self verify: capabilities.
	self verify: initializeResponse.
	self verify: loadResult.
	self verify: mockClient.
	self assert: session sessionId equals: 'session-1-loaded'
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientFallsBackToNewSessionWhenResumeAndLoadUnsupported [

	| topic session capabilities initializeResponse newSessionResult mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.
	capabilities := MockObject new.
	capabilities on: #isResumeSupported verify: [ false ].
	capabilities on: #isLoadSupported verify: [ false ].
	initializeResponse := self
		                      mockInitializeResponseWithCapabilities: capabilities.
	newSessionResult := self mockSessionResultWithId: 'session-2-new'.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :handler | ].
	mockClient
		on: #agentCommand:arguments:
		with: '/usr/bin/env'
		with: topic agentArguments
		verify: [ ].
	mockClient on: #connect verify: [ ].
	mockClient
		on: #initializeBy:
		with: MockObject any
		verify: [ :unused | initializeResponse ].
	mockClient
		on: #newSessionBy:
		with: MockObject any
		verify: [ :unused | newSessionResult ].

	session doConnectWithClient: mockClient.

	self verify: capabilities.
	self verify: initializeResponse.
	self verify: newSessionResult.
	self verify: mockClient.
	self assert: session sessionId equals: 'session-2-new'
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientUsesResumeWhenSessionIdExistsAndResumeSupported [

	| topic session capabilities initializeResponse resumeResult mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.
	capabilities := MockObject new.
	capabilities on: #isResumeSupported verify: [ true ].
	initializeResponse := self
		                      mockInitializeResponseWithCapabilities: capabilities.
	resumeResult := self mockSessionResultWithId: 'session-1-resumed'.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :handler | ].
	mockClient
		on: #agentCommand:arguments:
		with: '/usr/bin/env'
		with: topic agentArguments
		verify: [ ].
	mockClient on: #connect verify: [ ].
	mockClient
		on: #initializeBy:
		with: MockObject any
		verify: [ :unused | initializeResponse ].
	mockClient
		on: #resumeSessionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPResumeSessionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			resumeResult ].

	session doConnectWithClient: mockClient.

	self verify: capabilities.
	self verify: initializeResponse.
	self verify: resumeResult.
	self verify: mockClient.
	self assert: session sessionId equals: 'session-1-resumed'
]

{ #category : 'tests' }
AbTopicSessionTest >> testUpdateAvailableCommandsStoresCommands [

	| session topic commands |
	topic := AbTopic new.
	session := topic session.
	commands := OrderedCollection
		with: (ACPAvailableCommand new rawValues: (Dictionary new
					  at: 'name' put: '/help';
					  at: 'description' put: 'Show help';
					  yourself))
		with: (ACPAvailableCommand new rawValues: (Dictionary new
					  at: 'name' put: '/status';
					  at: 'description' put: 'Show status';
					  yourself)).

	session updateAvailableCommands: commands.

	self assert: topic availableCommands size equals: 2
]

{ #category : 'tests' }
AbTopicSessionTest >> testUpdateCurrentModelFromConfigOptionsExtractsModelCurrentValue [

	| session topic options modelOption |
	topic := AbTopic new.
	session := topic session.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'currentValue' put: 'claude-opus-4'.
	options := OrderedCollection with: modelOption.

	session updateCurrentModelFromConfigOptions: options.

	self assert: topic currentModel equals: 'claude-opus-4'
]
