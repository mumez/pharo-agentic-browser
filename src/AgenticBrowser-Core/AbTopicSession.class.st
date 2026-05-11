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

{ #category : 'instance creation' }
AbTopicSession class >> on: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'accessing' }
AbTopicSession >> availableCommands [
	^ availableCommands
]

{ #category : 'accessing' }
AbTopicSession >> announcer [
	^ self topic announcer
]

{ #category : 'accessing' }
AbTopicSession >> availableCommands: aCollection [
	availableCommands := aCollection
]

{ #category : 'accessing' }
AbTopicSession >> client [
	^ client
]

{ #category : 'accessing' }
AbTopicSession >> client: anACPClient [
	client := anACPClient
]

{ #category : 'private' }
AbTopicSession >> doConnect [

	| sessionResult |
	self client: ACPClient new.
	self client handler: (AbTopicHandler new topic: self topic; yourself).
	self client agentCommand: '/usr/bin/env' arguments: self topic agentArguments.
	self client connect.
	self client initializeBy: [ :params | "use defaults" ].
	sessionResult := self client newSessionBy: [ :params |
						 params cwd: self topic ensureWorkingDirectoryForConnection ].
	self sessionId: sessionResult sessionId.
	self updateCurrentModelFromConfigOptions: sessionResult configOptions
]

{ #category : 'operations' }
AbTopicSession >> disconnect [

	self client ifNotNil: [ self client disconnect ].
	self client: nil.
	self sessionId: nil.
	self availableCommands: OrderedCollection new.
	self currentModel: nil
]

{ #category : 'private' }
AbTopicSession >> ensureConnected [

	self client ifNil: [ self doConnect ]
]

{ #category : 'accessing' }
AbTopicSession >> currentModel [
	^ currentModel
]

{ #category : 'accessing' }
AbTopicSession >> currentModel: aString [
	currentModel := aString
]

{ #category : 'initialization' }
AbTopicSession >> initialize [

	availableCommands := OrderedCollection new
]

{ #category : 'accessing' }
AbTopicSession >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
AbTopicSession >> sessionId: aString [
	sessionId := aString
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
