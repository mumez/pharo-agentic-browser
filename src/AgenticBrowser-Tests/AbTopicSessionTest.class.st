Class {
	#name : 'AbTopicSessionTest',
	#superclass : 'AbTestCase',
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
AbTopicSessionTest >> testAnnouncerDelegatesToTopicAnnouncer [

	| topic session |
	topic := AbTopic new.
	session := topic session.
	self assert: session announcer equals: topic announcer
]

{ #category : 'tests' }
AbTopicSessionTest >> testClearSessionIdClearsSessionId [

	| topic session |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.

	session clearSessionId.

	self assert: session sessionId isNil
]

{ #category : 'tests' }
AbTopicSessionTest >> testConnectResponsibilityMovedToSession [

	self assert: (AbTopicSession canUnderstand: #doConnect).
	self assert: (AbTopicSession canUnderstand: #ensureConnected).
	self deny: (AbTopic canUnderstand: #doConnect).
	self deny: (AbTopic canUnderstand: #ensureConnected)
]

{ #category : 'tests' }
AbTopicSessionTest >> testDisconnectKeepsSessionIdAndClearsTransientFields [

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
	self assert: session sessionId equals: 'session-1'.
	self assert: session currentModel isNil.
	self assert: session availableCommands isEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientFallsBackToLoadWhenResumeUnsupported [

	| topic session capabilities initializeResponse loadResult mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.
	capabilities := ACPAgentCapabilities fromDictionary: (Dictionary new
		at: 'loadSession' put: true;
		yourself).
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
			params := ACPSessionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			loadResult ].

	session doConnectWithClient: mockClient.

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
	capabilities := ACPAgentCapabilities fromDictionary: Dictionary new.
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

	self verify: initializeResponse.
	self verify: newSessionResult.
	self verify: mockClient.
	self assert: session sessionId equals: 'session-2-new'
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientPassesMcpServersWhenMcpCapabilitiesPresent [

	| topic session newSessionResult mockClient capturedMcpServers capabilities initializeResponse |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	newSessionResult := self mockSessionResultWithId: 'session-new'.
	capabilities := ACPAgentCapabilities fromDictionary: (Dictionary new
		at: 'mcpCapabilities' put: (Dictionary new at: 'http' put: true; yourself);
		yourself).
	initializeResponse := self mockInitializeResponseWithCapabilities: capabilities.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :h | ].
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
		verify: [ :aBlock |
			| params |
			params := ACPSessionParams buildBy: aBlock.
			capturedMcpServers := params mcpServers.
			newSessionResult ].

	session doConnectWithClient: mockClient.

	self verify: mockClient.
	self assert: capturedMcpServers isCollection.
	self assert: capturedMcpServers notEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientSkipsMcpServersWhenMcpCapabilitiesAbsent [

	| topic session newSessionResult mockClient capturedMcpServers |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	newSessionResult := self mockSessionResultWithId: 'session-new'.
	mockClient := MockObject new.
	mockClient on: #handler: with: MockObject any verify: [ :h | ].
	mockClient
		on: #agentCommand:arguments:
		with: '/usr/bin/env'
		with: topic agentArguments
		verify: [ ].
	mockClient on: #connect verify: [ ].
	mockClient
		on: #initializeBy:
		with: MockObject any
		verify: [ :unused | nil ].
	mockClient
		on: #newSessionBy:
		with: MockObject any
		verify: [ :aBlock |
			| params |
			params := ACPSessionParams buildBy: aBlock.
			capturedMcpServers := params mcpServers.
			newSessionResult ].

	session doConnectWithClient: mockClient.

	self verify: mockClient.
	self assert: capturedMcpServers isEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testDoConnectWithClientUsesResumeWhenSessionIdExistsAndResumeSupported [

	| topic session capabilities initializeResponse resumeResult mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	session sessionId: 'session-1'.
	capabilities := ACPAgentCapabilities fromDictionary: (Dictionary new
		at: 'sessionCapabilities' put: (Dictionary new at: 'resume' put: Dictionary new; yourself);
		yourself).
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
			params := ACPSessionParams buildBy: aBlock.
			self assert: params sessionId equals: 'session-1'.
			resumeResult ].

	session doConnectWithClient: mockClient.

	self verify: initializeResponse.
	self verify: resumeResult.
	self verify: mockClient.
	self assert: session sessionId equals: 'session-1-resumed'
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

{ #category : 'tests' }
AbTopicSessionTest >> testUpdateConfigOptionsExtractsModeCurrentValue [

	| session topic options |
	topic := AbTopic new.
	session := topic session.
	options := OrderedCollection with: (self modeOptionWithCurrentValue: 'ask').

	session updateConfigOptions: options.

	self assert: topic currentMode equals: 'ask'
]

{ #category : 'tests' }
AbTopicSessionTest >> testSetConfigOptionIdValueCallsAcpClient [

	| topic session mockClient result resultOptions |
	topic := AbTopic new.
	session := topic session.
	session sessionId: 'session-1'.
	resultOptions := OrderedCollection with: (self modeOptionWithCurrentValue: 'code').
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

	session setConfigOptionId: 'mode' value: 'code'.

	self verify: result.
	self verify: mockClient.
	self assert: topic currentMode equals: 'code'
]
