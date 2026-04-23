Class {
	#name : 'AbTopic',
	#superclass : 'Object',
	#instVars : [
		'title',
		'agentArguments',
		'messages',
		'client',
		'sessionId',
		'stateMachine',
		'announcer',
		'watchedPackages'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'initialization' }
AbTopic >> initialize [

	title := 'Untitled'.
	agentArguments := #( 'claude-agent-acp' ).
	messages := OrderedCollection new.
	watchedPackages := OrderedCollection new.
	self initializeStateMachine
]

{ #category : 'initialization' }
AbTopic >> initializeStateMachine [

	stateMachine := SsStateMachine new.
	(stateMachine addStateNamed: #idle)
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #working)
		entryAction: [ self announceStatusChanged ];
		when: #permissionRequested to: #waitingForHuman;
		when: #ended to: #done.
	(stateMachine addStateNamed: #waitingForHuman)
		entryAction: [ self announceStatusChanged ];
		when: #humanResponded to: #working.
	(stateMachine addStateNamed: #done)
		entryAction: [ self announceStatusChanged ];
		when: #promptSent to: #working.
	stateMachine setStartStateTo: #idle.
	stateMachine start
]

{ #category : 'accessing' }
AbTopic >> title [
	^ title
]

{ #category : 'accessing' }
AbTopic >> title: aString [
	title := aString
]

{ #category : 'accessing' }
AbTopic >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbTopic >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> client [
	^ client
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
AbTopic >> stateMachine [
	^ stateMachine
]

{ #category : 'accessing' }
AbTopic >> watchedPackages [
	^ watchedPackages
]

{ #category : 'accessing' }
AbTopic >> status [
	^ stateMachine currentState name
]

{ #category : 'accessing' }
AbTopic >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	| msg |
	msg := AbMessage sender: #human text: aString.
	messages add: msg.
	self announceMessageAdded: msg.
	stateMachine handleEvent: #promptSent.
	[
	| result |
	self ensureConnected.
	result := client promptBy: [ :params |
		          params sessionId: sessionId.
		          params textPrompt: aString ].
	result stopReason = 'end_turn' ifTrue: [
		stateMachine handleEvent: #ended ] ] fork
]

{ #category : 'operations' }
AbTopic >> addAiTextChunk: aString [

	| msg |
	(messages notEmpty and: [
		 messages last sender = #ai and: [ messages last isApprovalRequest not ] ])
		ifTrue: [ messages last appendText: aString ]
		ifFalse: [
			msg := AbMessage sender: #ai text: aString.
			messages add: msg ].
	self announceMessageAdded: messages last
]

{ #category : 'operations' }
AbTopic >> addApprovalRequest: aDescription [

	| msg |
	msg := AbMessage approvalRequestText: aDescription.
	messages add: msg.
	self announceMessageAdded: msg.
	^ msg
]

{ #category : 'operations' }
AbTopic >> resolveApproval: aUserText [

	| pending response |
	pending := messages
		           detect: [ :m |
			           m isApprovalRequest and: [ m approvalResponse isNil ] ]
		           ifNone: [ ^ self ].
	response := (aUserText trimmed asLowercase includesSubstring: 'no') |
	            (aUserText trimmed asLowercase includesSubstring: 'deny') |
	            (aUserText trimmed asLowercase includesSubstring: 'reject')
		            ifTrue: [ #rejectOnce ]
		            ifFalse: [ #allowAlways ].
	pending approvalResponse: response.
	stateMachine handleEvent: #humanResponded.
	pending approvalSemaphore signal
]

{ #category : 'operations' }
AbTopic >> disconnect [

	client ifNotNil: [
		client disconnect.
		client := nil.
		sessionId := nil ]
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	client isNil ifTrue: [ self doConnect ]
]

{ #category : 'private' }
AbTopic >> doConnect [

	| sessionResult |
	client := ACPClient new.
	client handler: (AbTopicHandler new topic: self; yourself).
	client agentCommand: '/usr/bin/env' arguments: agentArguments.
	client connect.
	client initializeBy: [ :params | "use defaults" ].
	sessionResult := client newSessionBy: [ :params |
		                 params cwd: FileSystem workingDirectory fullName ].
	sessionId := sessionResult sessionId
]

{ #category : 'private' }
AbTopic >> announceStatusChanged [

	self announcer announce:
		(AbTopicStatusChanged new topic: self; yourself)
]

{ #category : 'private' }
AbTopic >> announceMessageAdded: aMessage [

	self announcer announce: (AbMessageAdded new
		 topic: self;
		 message: aMessage;
		 yourself)
]
