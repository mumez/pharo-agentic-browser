Class {
	#name : 'AbTopicSessionTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

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
