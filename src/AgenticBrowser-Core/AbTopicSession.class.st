Class {
	#name : 'AbTopicSession',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'client',
		'sessionId',
		'availableCommands',
		'currentModel'
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
	^ availableCommands
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

{ #category : 'operations' }
AbTopicSession >> disconnect [

	self client ifNotNil: [ self client disconnect ].
	self client: nil.
	self availableCommands: OrderedCollection new.
	self currentModel: nil
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
	self updateCurrentModelFromConfigOptions: sessionResult configOptions
]

{ #category : 'private' }
AbTopicSession >> ensureConnected [

	self client ifNil: [ self doConnect ]
]

{ #category : 'initialization' }
AbTopicSession >> initialize [

	availableCommands := OrderedCollection new
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
AbTopicSession >> sessionResultFromInitializeResponse: initializeResponse [

	| existingSessionId workingDirectoryPath capabilities mcpServers |
	existingSessionId := self sessionId.
	workingDirectoryPath := self topic ensureWorkingDirectoryForConnection.
	mcpServers := self resolvedMcpServers.
	(existingSessionId notNil and: [ initializeResponse notNil ]) ifTrue: [
		capabilities := initializeResponse agentCapabilities.
		(capabilities notNil and: [ capabilities isResumeSupported ]) ifTrue: [
			^ self client resumeSessionBy: [ :params |
				  params
					  sessionId: existingSessionId;
					  cwd: workingDirectoryPath;
					  mcpServers: mcpServers ] ].
		(capabilities notNil and: [ capabilities isLoadSupported ]) ifTrue: [
			^ self client loadSessionBy: [ :params |
				  params
					  sessionId: existingSessionId;
					  cwd: workingDirectoryPath;
					  mcpServers: mcpServers ] ] ].
	^ self client newSessionBy: [ :params |
		  params
			  cwd: workingDirectoryPath;
			  mcpServers: mcpServers ]
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
AbTopicSession >> updateCurrentModelFromConfigOptions: aCollection [

	| modelOption |
	modelOption := aCollection detect: [ :opt | opt isModelCategory ] ifNone: [ ^ self ].
	self currentModel: modelOption currentValue.
	self announcer announce: (AbTopicCurrentModelChanged new
			 topic: self topic;
			 model: self currentModel;
			 yourself)
]
