"
I manage the ACP client connection to an AI agent on behalf of an AbTopic.

Responsibility:
- I handle connecting, disconnecting, and reconnecting to the ACP agent process.
- I resume or create agent sessions, preferring resume when the agent supports it.
- I load and register MCP servers on session establishment via AbMcpServersLoader.
- I track the agent's current model, mode, and available slash commands via config options.
- I fire announcements when model, mode, or available commands change.

Collaborators:
- AbTopic: I am owned by a topic; I delegate back to it for working directory setup and as handler target.
- AbTopicHandler: I set it as the ACP client handler to receive agent callbacks.
- AbMcpServersLoader: I call it to resolve the MCP server list on every connect.
- ACPClient: I create and manage the low-level ACP protocol client.

Public API and Key Messages:
- #ensureConnected - Connect lazily on first use; resume existing session if possible.
- #disconnect - Cleanly disconnect the ACP client and reset derived state.
- #setConfigOptionId:value: - Send a config change to the agent (e.g. model/mode selection).
- #updateConfigOptions: - Synchronize config options and announce model/mode changes.
- #sessionId - The persistent ACP session identifier used for resume/load.

Internal Representation:
- client - The ACPClient instance; nil when not connected (excluded from Fuel serialization).
- sessionId - Persisted across image restarts; used to resume agent sessions.
- availableCommands - Slash commands reported by the agent; persisted so the UI dropdown is populated before the next session connects.
- configOptions - OrderedCollection of ACPConfigOption from the agent; drives the UI droplists.
- currentModel / currentMode - Cached current values; suppress no-op announcements.

Implementation Points:
- client is excluded from Fuel serialization (fuelIgnoredInstanceVariableNames) and is recreated on next #ensureConnected.
- If the agent does not support MCP server registration, MCP servers are silently skipped and a system message is inserted into the topic.
- Session resume falls back to load, then to new session creation, based on agent capability flags.
- A plain image save/restart (not a Fuel reload) keeps client non-nil but pointing at a dead subprocess and its closed pipes; #disconnect always clears it even if the underlying client disconnect fails, so a fresh #ensureConnected can reconnect. AbTopicManager triggers this on image resume via its class-side #startUp:.
"
Class {
	#name : 'AbTopicSession',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'client',
		'sessionId',
		'availableCommands',
		'currentModel',
		'currentMode',
		'configOptions'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'fuel' }
AbTopicSession class >> fuelIgnoredInstanceVariableNames [

	^ #( 'client' )
]

{ #category : 'instance creation' }
AbTopicSession class >> on: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'accessing' }
AbTopicSession >> announcer [
	^ self topic announcer
]

{ #category : 'accessing' }
AbTopicSession >> availableCommands [
	^ availableCommands ifNil: [ availableCommands := OrderedCollection new ]
]

{ #category : 'accessing' }
AbTopicSession >> availableCommands: aCollection [
	availableCommands := aCollection
]

{ #category : 'operations' }
AbTopicSession >> clearSessionId [

	self sessionId: nil
]

{ #category : 'accessing' }
AbTopicSession >> client [
	^ client
]

{ #category : 'accessing' }
AbTopicSession >> client: anACPClient [
	client := anACPClient
]

{ #category : 'accessing' }
AbTopicSession >> currentModel [
	^ currentModel
]

{ #category : 'accessing' }
AbTopicSession >> currentModel: aString [
	currentModel := aString
]

{ #category : 'accessing' }
AbTopicSession >> currentMode [
	^ currentMode
]

{ #category : 'accessing' }
AbTopicSession >> currentMode: aString [
	currentMode := aString
]

{ #category : 'testing' }
AbTopicSession >> isConnected [
	^ self client notNil
]

{ #category : 'operations' }
AbTopicSession >> disconnect [
	"The client's subprocess pipes may already be dead (e.g. after a Pharo image restart
	while the topic stayed open), so a graceful protocol disconnect can itself fail.
	Always clear the client so the next #ensureConnected reconnects instead of reusing it."

	[ self client ifNotNil: [ self client disconnect ] ]
		on: Error
		do: [ :e | "ignore: the connection is already unusable" ].
	self initClientDerived
]

{ #category : 'private' }
AbTopicSession >> doConnect [

	self doConnectWithClient: ACPClient new
]

{ #category : 'private' }
AbTopicSession >> doConnectWithClient: anACPClient [

	| initializeResult sessionResult |
	self client: anACPClient.
	self client handler: (AbTopicHandler new topic: self topic; yourself).
	self client agentCommand: '/usr/bin/env' arguments: self topic agentArguments.
	self client connect.
	initializeResult := self client initializeBy: [ :params | "use defaults" ].
	sessionResult := self sessionResultFromInitializeResponse: initializeResult.
	sessionResult sessionId ifNotNil: [ :sid | self sessionId: sid ].
	self updateConfigOptions: sessionResult configOptions
]

{ #category : 'private' }
AbTopicSession >> ensureConnected [

	self client ifNil: [ self doConnect ]
]

{ #category : 'initialization' }
AbTopicSession >> initialize [
    topic := nil.
    sessionId := nil.
    self initClientDerived
]

{ #category : 'initialization' }
AbTopicSession >> initClientDerived [
    client := nil.
    currentModel := nil.
    currentMode := nil.
    configOptions := nil
]

{ #category : 'accessing' }
AbTopicSession >> configOptions [
	^ configOptions ifNil: [ configOptions := OrderedCollection new ]
]

{ #category : 'accessing' }
AbTopicSession >> configOptions: aCollection [
	configOptions := aCollection ifNotNil: [ :c | c asOrderedCollection ]
]

{ #category : 'accessing' }
AbTopicSession >> modelConfigOption [
	^ self detectModelFrom: self configOptions
]

{ #category : 'accessing' }
AbTopicSession >> modeConfigOption [
	^ self detectModeFrom: self configOptions
]

{ #category : 'private' }
AbTopicSession >> detectModeFrom: aCollection [
	^ aCollection detect: [ :opt | opt isModeCategory ] ifNone: [ nil ]
]

{ #category : 'private' }
AbTopicSession >> detectModelFrom: aCollection [
	^ aCollection detect: [ :opt | opt isModelCategory ] ifNone: [ nil ]
]

{ #category : 'private' }
AbTopicSession >> resolvedMcpServers [

	^ AbMcpServersLoader new load
]

{ #category : 'accessing' }
AbTopicSession >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
AbTopicSession >> sessionId: aString [
	sessionId := aString
]

{ #category : 'private' }
AbTopicSession >> capabilitiesFrom: initializeResponse [

	^ initializeResponse ifNotNil: [ initializeResponse agentCapabilities ]
]

{ #category : 'private' }
AbTopicSession >> notifyMcpServersNotRegistered: servers [

	servers ifNotEmpty: [
		self topic addSystemMessage:
			'Note: MCP servers are configured but this agent does not support MCP server registration.' ]
]

{ #category : 'private' }
AbTopicSession >> createSessionAt: workingDirectoryPath mcpServers: mcpServers [

	^ self client newSessionBy: [ :params |
		  params
			  cwd: workingDirectoryPath;
			  mcpServers: mcpServers ]
]

{ #category : 'private' }
AbTopicSession >> resumeOrCreateSessionAt: workingDirectoryPath mcpServers: mcpServers capabilities: capabilities [

	| existingSessionId |
	existingSessionId := self sessionId.
	existingSessionId ifNil: [ ^ self createSessionAt: workingDirectoryPath mcpServers: mcpServers ].
	capabilities ifNil: [ ^ self createSessionAt: workingDirectoryPath mcpServers: mcpServers ].
	capabilities isResumeSupported ifTrue: [
		^ self client resumeSessionBy: [ :params |
			  params sessionId: existingSessionId; cwd: workingDirectoryPath; mcpServers: mcpServers ] ].
	capabilities isLoadSupported ifTrue: [
		^ self client loadSessionBy: [ :params |
			  params sessionId: existingSessionId; cwd: workingDirectoryPath; mcpServers: mcpServers ] ].
	^ self createSessionAt: workingDirectoryPath mcpServers: mcpServers
]

{ #category : 'private' }
AbTopicSession >> sessionResultFromInitializeResponse: initializeResponse [

	| capabilities mcpServers workingDirectoryPath |
	capabilities := self capabilitiesFrom: initializeResponse.
	mcpServers := self resolvedMcpServers.
	(capabilities isNil or: [ capabilities isMcpServersSupported not ]) ifTrue: [
		self notifyMcpServersNotRegistered: mcpServers.
		mcpServers := #() ].
	workingDirectoryPath := self topic ensureWorkingDirectoryForConnection.
	^ self
		  resumeOrCreateSessionAt: workingDirectoryPath
		  mcpServers: mcpServers
		  capabilities: capabilities
]

{ #category : 'accessing' }
AbTopicSession >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicSession >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'operations' }
AbTopicSession >> updateAvailableCommands: aCollection [

	self availableCommands: aCollection asOrderedCollection.
	self announcer announce: (AbTopicAvailableCommandsChanged new
			 topic: self topic;
			 commands: self availableCommands;
			 yourself)
]

{ #category : 'operations' }
AbTopicSession >> updateCurrentModel: aModelOption [

	| newModel |
	aModelOption ifNil: [ ^ self ].
	newModel := aModelOption currentValue.
	newModel = self currentModel ifTrue: [ ^ self ].
	self currentModel: newModel.
	self announcer announce: (AbTopicCurrentModelChanged new
			 topic: self topic;
			 model: self currentModel;
			 yourself)
]

{ #category : 'operations' }
AbTopicSession >> updateCurrentMode: aModeOption [

	| newMode |
	aModeOption ifNil: [ ^ self ].
	newMode := aModeOption currentValue.
	newMode = self currentMode ifTrue: [ ^ self ].
	self currentMode: newMode.
	self announcer announce: (AbTopicCurrentModeChanged new
			 topic: self topic;
			 mode: self currentMode;
			 yourself)
]

{ #category : 'operations' }
AbTopicSession >> updateConfigOptions: aCollection [

	self configOptions: aCollection.
	self updateCurrentMode: (self detectModeFrom: self configOptions).
	self updateCurrentModel: (self detectModelFrom: self configOptions)
]

{ #category : 'operations' }
AbTopicSession >> setConfigOptionId: aConfigId value: aValue [

	| result |
	self ensureConnected.
	result := self client setSessionConfigOptionBy: [ :params |
		          params
			          sessionId: self sessionId;
			          configId: aConfigId;
			          value: aValue ].
	self updateConfigOptions: result configOptions
]
