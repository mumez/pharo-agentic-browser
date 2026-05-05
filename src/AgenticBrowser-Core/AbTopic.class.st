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
		'topicId',
		'packagePrefixes',
		'updatedExternalPackageNames',
		'workingDirectory',
		'relatedPackagesWatcher',
		'workingDirectoryPath',
		'logger'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'operations' }
AbTopic >> addAiTextChunk: aString [

	self addAiChunk: aString think: false
]

{ #category : 'operations' }
AbTopic >> addAiThoughtChunk: aString [

	self addAiChunk: aString think: true
]

{ #category : 'private' }
AbTopic >> addAiChunk: aString think: aBoolean [

	| msg |
	(messages notEmpty and: [
			 messages last sender = #ai and: [
				 messages last isApprovalRequest not and: [
					 messages last isThink = aBoolean ] ] ])
		ifTrue: [ messages last appendText: aString ]
		ifFalse: [
			msg := AbMessage sender: #ai text: aString isThink: aBoolean.
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
AbTopic >> addPackagePrefix: aString [

	packagePrefixes add: aString
]

{ #category : 'operations' }
AbTopic >> addUpdatedExternalPackageName: aString [

	updatedExternalPackageNames add: aString
]

{ #category : 'operations' }
AbTopic >> addSystemMessage: aString [

	| msg |
	msg := AbMessage sender: #system text: aString.
	messages add: msg.
	self announceMessageAdded: msg
]

{ #category : 'accessing' }
AbTopic >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbTopic >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'private' }
AbTopic >> announceMessageAdded: aMessage [

	self announcer announce: (AbMessageAdded new
			 topic: self;
			 message: aMessage;
			 yourself)
]

{ #category : 'private' }
AbTopic >> announceStatusChanged: updatedStatus [

	self logger debug: 'announceStatusChanged: topic='
		, self title printString
		, ' status='
		, updatedStatus printString.
	self announcer announce:
		(AbTopicStatusChanged new topic: self; status: updatedStatus; yourself)
]

{ #category : 'accessing' }
AbTopic >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbTopic >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbTopic >> client [
	^ client
]

{ #category : 'operations' }
AbTopic >> disconnect [

	client ifNotNil: [
		client disconnect.
		client := nil.
		sessionId := nil ]
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
						 params cwd: self ensureWorkingDirectoryForConnection ].
	sessionId := sessionResult sessionId
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	client isNil ifTrue: [ self doConnect ]
]

{ #category : 'private' }
AbTopic >> ensureWorkingDirectoryForConnection [

	self workingDirectory ensureExists.
	self workingDirectory subscribeToSisServerImportEvents.
	self relatedPackagesWatcher isWatching ifFalse: [ self startWatching ].
	^ self workingDirectory path fullName
]


{ #category : 'accessing' }
AbTopic >> relatedPackagesWatcher [

	^ relatedPackagesWatcher ifNil: [ relatedPackagesWatcher := AbTopicRelatedPackagesWatcher forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> hasPackagePrefix: aString [

	^ packagePrefixes includes: aString
]

{ #category : 'accessing' }
AbTopic >> hasPendingApprovalRequest [

	^ messages anySatisfy: [ :m |
		  m isApprovalRequest and: [ m approvalResponse isNil ] ]
]

{ #category : 'testing' }
AbTopic >> isEndTurn [

	^ self status = #endTurn
]

{ #category : 'testing' }
AbTopic >> isInitial [

	^ self status = #initial
]

{ #category : 'testing' }
AbTopic >> isWaitingForHuman [

	^ self status = #waitingForHuman
]

{ #category : 'testing' }
AbTopic >> isWorking [

	^ self status = #working
]



{ #category : 'initialization' }
AbTopic >> initialize [

	title := 'Untitled'.
	agentArguments := #( 'claude-agent-acp' ).
	messages := OrderedCollection new.
	packagePrefixes := Set new.
	updatedExternalPackageNames := Set new.
	topicId := UUID new asString.
	self initializeStateMachine
]


{ #category : 'initialization' }
AbTopic >> initializeStateMachine [

	stateMachine := SsStateMachine new.
	(stateMachine addStateNamed: #initial)
		when: #permissionRequested to: #waitingForHuman;
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #working)
		entryAction: [ self announceStatusChanged: #working ];
		when: #permissionRequested to: #waitingForHuman;
		when: #turnEnded to: #endTurn.
	(stateMachine addStateNamed: #waitingForHuman)
		entryAction: [ self announceStatusChanged: #waitingForHuman ];
		when: #humanResponded to: #working.
	(stateMachine addStateNamed: #endTurn)
		entryAction: [ self announceStatusChanged: #endTurn ];
		when: #permissionRequested to: #waitingForHuman;
		when: #promptSent to: #working.
	stateMachine setStartStateTo: #initial.
	stateMachine start
]

{ #category : 'accessing' }
AbTopic >> matchingPackageNames [

	packagePrefixes isEmpty ifTrue: [ ^ #() ].
	^ (PackageOrganizer default packages
			 select: [ :p |
				 packagePrefixes anySatisfy: [ :prefix |
					 prefix match: p name asString ] ]
			 thenCollect: [ :p | p name asString ])
		  asSortedCollection asArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> packagePrefixes [
	^ packagePrefixes
]

{ #category : 'accessing' }
AbTopic >> packagePrefixes: aCollection [
	packagePrefixes := aCollection asSet
]

{ #category : 'accessing' }
AbTopic >> updatedExternalPackageNames [
	^ updatedExternalPackageNames
]

{ #category : 'operations' }
AbTopic >> removePackagePrefix: aString [

	packagePrefixes remove: aString ifAbsent: []
]

{ #category : 'operations' }
AbTopic >> clearUpdatedExternalPackageNames [

	updatedExternalPackageNames removeAll
]

{ #category : 'operations' }
AbTopic >> resolveApproval: aUserText [

	| pending response |
	self logger debug: 'resolveApproval: entered userText=' , aUserText printString.
	self logger debug: 'resolveApproval: status(before humanResponded)='
		, self status printString.
	pending := messages
					   detect: [ :m |
						   m isApprovalRequest and: [ m approvalResponse isNil ] ]
					   ifNone: [
						   self logger debug: 'resolveApproval: no pending approval found, returning'.
						   ^ self ].
	response := (aUserText trimmed asLowercase includesSubstring: 'no') |
				(aUserText trimmed asLowercase includesSubstring: 'deny') |
				(aUserText trimmed asLowercase includesSubstring: 'reject')
					ifTrue: [ #rejectOnce ]
					ifFalse: [ #allowAlways ].
	self logger debug: 'resolveApproval: response=' , response printString.
	pending approvalResponse: response.
	stateMachine handleEvent: #humanResponded.
	self logger debug: 'resolveApproval: status(after humanResponded)='
		, self status printString.
	self logger debug: 'resolveApproval: done'
]

{ #category : 'operations' }
AbTopic >> requestApproval: aDescription [

	| msg waitSeconds wasInitial |
	wasInitial := self isInitial.
	self logger debug: 'requestApproval: waiting for human approval. description=' , aDescription printString.
	self logger debug: 'requestApproval: status(before permissionRequested)='
		, self status printString.
	msg := self addApprovalRequest: aDescription.
	stateMachine handleEvent: #permissionRequested.
	self logger debug: 'requestApproval: status(after permissionRequested)='
		, self status printString.

	waitSeconds := 0.
	[ msg approvalResponse isNil and: [ waitSeconds < AbSettings default approvalWaitTimeoutSeconds ] ] whileTrue: [
		1 second wait.
		waitSeconds := waitSeconds + 1 ].

	msg approvalResponse ifNil: [
		self logger debug: 'requestApproval: timeout reached, auto rejecting'.
		msg approvalResponse: #rejectOnce.
		self isWaitingForHuman ifTrue: [
			stateMachine handleEvent: #humanResponded ] ].

	wasInitial ifTrue: [ stateMachine handleEvent: #turnEnded ].
	wasInitial ifTrue: [
		self logger debug: 'requestApproval: status(after turnEnded from initial)='
			, self status printString ].

	self logger debug: 'requestApproval: done. response=' , msg approvalResponse printString.
	^ msg approvalResponse ifNil: [ #rejectOnce ]
]

{ #category : 'operations' }
AbTopic >> cancelPrompt [

	self isWorking ifFalse: [ ^ self ].
	client ifNotNil: [
		client cancelBy: [ :params | params sessionId: sessionId ] ].
	stateMachine handleEvent: #turnEnded
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
			stateMachine handleEvent: #turnEnded ] ] fork
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ sessionId
]

{ #category : 'operations' }
AbTopic >> startWatching [

	self relatedPackagesWatcher start
]

{ #category : 'accessing' }
AbTopic >> stateMachine [
	^ stateMachine
]

{ #category : 'accessing' }
AbTopic >> status [
	^ stateMachine currentState name
]

{ #category : 'operations' }
AbTopic >> stopWatching [

	relatedPackagesWatcher ifNotNil: [ relatedPackagesWatcher stop ]
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
AbTopic >> topicId [
	^ topicId
]

{ #category : 'accessing' }
AbTopic >> defaultWorkingDirectoryPath [

	^ (Smalltalk imageDirectory / 'agentic-browser'
	   / self workingDirectory directoryName) fullName
]

{ #category : 'accessing' }
AbTopic >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := AbWorkingDirectory forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> workingDirectoryPath [

	^ workingDirectoryPath ifNil: [ workingDirectoryPath := self defaultWorkingDirectoryPath ]
]

{ #category : 'accessing' }
AbTopic >> workingDirectoryPath: aString [

	| previousWorkingDirectory |
	previousWorkingDirectory := workingDirectory.
	previousWorkingDirectory ifNotNil: [
		previousWorkingDirectory unsubscribeFromSisServerImportEvents ].
	workingDirectoryPath := aString.
	workingDirectory := nil
]
