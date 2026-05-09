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
		'logger',
		'availableCommands',
		'topicGoal',
		'currentModel'
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
	(self messages notEmpty and: [
			 self messages last sender = #ai and: [
				 self messages last isApprovalRequest not and: [
					 self messages last isThink = aBoolean ] ] ])
		ifTrue: [ self messages last appendText: aString ]
		ifFalse: [
			msg := AbMessage sender: #ai text: aString isThink: aBoolean.
			self messages add: msg ].
	self announceMessageAdded: self messages last
]

{ #category : 'operations' }
AbTopic >> addApprovalRequest: aDescription [

	^ self
		  addApprovalRequest: aDescription
		  options: self defaultApprovalOptions
]

{ #category : 'operations' }
AbTopic >> addApprovalRequest: aDescription options: approvalOptions [

	| msg |
	msg := AbMessage
		       approvalRequestText: aDescription
		       options: approvalOptions.
	self messages add: msg.
	self announceMessageAdded: msg.
	^ msg
]

{ #category : 'operations' }
AbTopic >> addPackagePrefix: aString [

	self packagePrefixes add: aString
]

{ #category : 'operations' }
AbTopic >> addUpdatedExternalPackageName: aString [

	self updatedExternalPackageNames add: aString
]

{ #category : 'operations' }
AbTopic >> addSystemMessage: aString [

	| msg |
	msg := AbMessage sender: #system text: aString.
	self messages add: msg.
	self announceMessageAdded: msg
]

{ #category : 'accessing' }
AbTopic >> availableCommands [
	^ availableCommands
]

{ #category : 'accessing' }
AbTopic >> availableCommands: aCollection [
	availableCommands := aCollection
]

{ #category : 'operations' }
AbTopic >> updateAvailableCommands: aCollection [

	self availableCommands: aCollection asOrderedCollection.
	self announcer announce: (AbTopicAvailableCommandsChanged new
			 topic: self;
			 commands: self availableCommands;
			 yourself)
]

{ #category : 'accessing' }
AbTopic >> currentModel [
	^ currentModel
]

{ #category : 'operations' }
AbTopic >> updateCurrentModelFromConfigOptions: aCollection [

	| modelOption |
	modelOption := aCollection detect: [ :opt | opt isModelCategory ] ifNone: [ ^ self ].
	currentModel := modelOption currentValue.
	self announcer announce: (AbTopicCurrentModelChanged new
			 topic: self;
			 model: currentModel;
			 yourself)
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

	self client ifNotNil: [
		self client disconnect.
		self client: nil.
		self sessionId: nil ]
]

{ #category : 'private' }
AbTopic >> doConnect [

	| sessionResult |
	self client: ACPClient new.
	self client handler: (AbTopicHandler new topic: self; yourself).
	self client agentCommand: '/usr/bin/env' arguments: self agentArguments.
	self client connect.
	self client initializeBy: [ :params | "use defaults" ].
	sessionResult := self client newSessionBy: [ :params |
						 params cwd: self ensureWorkingDirectoryForConnection ].
	self sessionId: sessionResult sessionId.
	self updateCurrentModelFromConfigOptions:
		(sessionResult configOptions collect: [ :each | ACPConfigOption fromDictionary: each ])
]

{ #category : 'private' }
AbTopic >> ensureConnected [

	self client ifNil: [ self doConnect ]
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
AbTopic >> relatedPackagesWatcherIfPresent [

	^ relatedPackagesWatcher
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
AbTopic >> isGoalAchieved [

	^ self status = #goalAchieved
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
	availableCommands := OrderedCollection new.
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
		when: #turnEnded to: #endTurn;
		when: #goalReached to: #goalAchieved.
	(stateMachine addStateNamed: #waitingForHuman)
		entryAction: [ self announceStatusChanged: #waitingForHuman ];
		when: #humanResponded to: #working.
	(stateMachine addStateNamed: #endTurn)
		entryAction: [ self announceStatusChanged: #endTurn ];
		when: #permissionRequested to: #waitingForHuman;
		when: #promptSent to: #working.
	(stateMachine addStateNamed: #goalAchieved)
		entryAction: [ self announceStatusChanged: #goalAchieved ];
		when: #reset to: #initial.
	stateMachine setStartStateTo: #initial.
	stateMachine start
]

{ #category : 'accessing' }
AbTopic >> matchingPackageNames [

	self packagePrefixes ifEmpty: [ ^ #() ].
	^ (PackageOrganizer default packages
			 select: [ :p |
				 self packagePrefixes anySatisfy: [ :prefix |
					 prefix match: p name asString ] ]
			 thenCollect: [ :p | p name asString ])
		  asSortedCollection asArray
]

{ #category : 'accessing' }
AbTopic >> messages [
	^ messages
]

{ #category : 'accessing' }
AbTopic >> lastUpdated [

	self messages ifEmpty: [ ^ nil ].
	^ self messages
		  inject: self messages first lastUpdated
		  into: [ :latest :each | latest max: each lastUpdated ]
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

	self packagePrefixes remove: aString ifAbsent: []
]

{ #category : 'operations' }
AbTopic >> clearUpdatedExternalPackageNames [

	self updatedExternalPackageNames removeAll
]

{ #category : 'operations' }
AbTopic >> resolveApproval: aUserText [

	| pending response |
	self logger debug: 'resolveApproval: entered userText=' , aUserText printString.
	self logger debug: 'resolveApproval: status(before humanResponded)='
		, self status printString.
	pending := self pendingApprovalMessage.
	pending ifNil: [
		self logger debug: 'resolveApproval: no pending approval found, returning'.
		^ self ].
	response := self approvalResponseForUserText: aUserText.
	self logger debug: 'resolveApproval: response=' , response printString.
	self resolveApprovalWithOptionId: response
]

{ #category : 'operations' }
AbTopic >> resolveApprovalWithOptionId: anOptionId [

	| pending |
	pending := self pendingApprovalMessage.
	pending ifNil: [ ^ self ].
	pending approvalResponse: anOptionId.
	self stateMachine handleEvent: #humanResponded.
	self logger debug: 'resolveApproval: status(after humanResponded)='
		, self status printString.
	self logger debug: 'resolveApproval: done'
]

{ #category : 'private' }
AbTopic >> pendingApprovalMessage [

	^ self messages
		detect: [ :m | m isApprovalRequest and: [ m approvalResponse isNil ] ]
		ifNone: [ nil ]
]

{ #category : 'private' }
AbTopic >> approvalResponseForUserText: aUserText [

	^ (aUserText trimmed asLowercase includesSubstring: 'no')
		  | (aUserText trimmed asLowercase includesSubstring: 'deny')
		  | (aUserText trimmed asLowercase includesSubstring: 'reject')
			ifTrue: [ #rejectOnce ]
			ifFalse: [ #allowOnce ]
]

{ #category : 'operations' }
AbTopic >> requestApproval: aDescription [

	^ self requestApproval: aDescription options: self defaultApprovalOptions
]

{ #category : 'operations' }
AbTopic >> requestApproval: aDescription options: approvalOptions [

	| msg wasInitial |
	wasInitial := self isInitial.
	self logRequestApprovalStart: aDescription.
	msg := self
		       addApprovalRequestAndWaitForHuman: aDescription
		       options: approvalOptions.
	self waitForApprovalResponseOf: msg.
	self rejectApprovalOnTimeout: msg.
	self finishApprovalRequestIfNeededForInitialState: wasInitial.
	self logger debug: 'requestApproval: done. response=' , msg approvalResponse printString.
	^ msg approvalResponse ifNil: [ #rejectOnce ]
]

{ #category : 'private' }
AbTopic >> logRequestApprovalStart: aDescription [

	self logger debug: 'requestApproval: waiting for human approval. description=' , aDescription printString.
	self logger debug: 'requestApproval: status(before permissionRequested)='
		, self status printString
]

{ #category : 'private' }
AbTopic >> addApprovalRequestAndWaitForHuman: aDescription options: approvalOptions [

	| msg |
	msg := self addApprovalRequest: aDescription options: approvalOptions.
	self stateMachine handleEvent: #permissionRequested.
	self logger debug: 'requestApproval: status(after permissionRequested)='
		, self status printString.
	^ msg
]

{ #category : 'private' }
AbTopic >> defaultApprovalOptions [

	^ {
		  'Confirm' -> #allowOnce.
		  'Deny' -> #rejectOnce }
]

{ #category : 'private' }
AbTopic >> waitForApprovalResponseOf: aMessage [

	| waitSeconds |
	waitSeconds := 0.
	[ aMessage approvalResponse isNil and: [ waitSeconds < AbSettings default approvalWaitTimeoutSeconds ] ] whileTrue: [
		1 second wait.
		waitSeconds := waitSeconds + 1 ]
]

{ #category : 'private' }
AbTopic >> rejectApprovalOnTimeout: aMessage [

	aMessage approvalResponse ifNotNil: [ ^ self ].
	self logger debug: 'requestApproval: timeout reached, auto rejecting'.
	aMessage approvalResponse: #rejectOnce.
	self isWaitingForHuman ifTrue: [
		self stateMachine handleEvent: #humanResponded ]
]

{ #category : 'private' }
AbTopic >> finishApprovalRequestIfNeededForInitialState: wasInitial [

	wasInitial ifFalse: [ ^ self ].
	self stateMachine handleEvent: #turnEnded.
	self logger debug: 'requestApproval: status(after turnEnded from initial)='
		, self status printString
]

{ #category : 'operations' }
AbTopic >> cancelPrompt [

	self isWorking ifFalse: [ ^ self ].
	self client ifNotNil: [
		self client cancelBy: [ :params | params sessionId: self sessionId ] ].
	self stateMachine handleEvent: #turnEnded
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	| msg |
	msg := AbMessage sender: #human text: aString.
	self messages add: msg.
	self announceMessageAdded: msg.
	self stateMachine handleEvent: #promptSent.
	[
	| result |
	self ensureConnected.
		result := self client promptBy: [ :params |
				  params sessionId: self sessionId.
				  params textPrompt: aString ].
		result stopReason = 'end_turn' ifTrue: [
			self checkGoalAchievement ifFalse: [
				self stateMachine handleEvent: #turnEnded ] ] ] fork
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
AbTopic >> sessionId: aString [

	sessionId := aString
]

{ #category : 'accessing' }
AbTopic >> client: anACPClient [

	client := anACPClient
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
	^ self stateMachine currentState name
]

{ #category : 'operations' }
AbTopic >> stopWatching [

	self relatedPackagesWatcherIfPresent ifNotNil: [ :watcher | watcher stop ]
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

{ #category : 'accessing' }
AbTopic >> topicGoal [
	^ topicGoal
]

{ #category : 'accessing' }
AbTopic >> topicGoal: anAbTopicGoal [
	topicGoal := anAbTopicGoal
]

{ #category : 'operations' }
AbTopic >> goalDescription: aString [

	self topicGoal: (AbTopicGoal on: self).
	self topicGoal description: aString.
	self sendPrompt: self topicGoal notificationPrompt
]

{ #category : 'operations' }
AbTopic >> checkGoalAchievement [

	self topicGoal ifNil: [ ^ false ].
	self topicGoal checkAchievement ifFalse: [ ^ false ].
	self stateMachine handleEvent: #goalReached.
	self announceGoalAchieved.
	self topicGoal runWhenAchievedBlock.
	^ true
]

{ #category : 'private' }
AbTopic >> announceGoalAchieved [

	self announcer announce: (AbTopicGoalAchieved new
			 topic: self;
			 goal: self topicGoal;
			 yourself)
]

{ #category : 'operations' }
AbTopic >> resetFromGoalAchieved [

	self stateMachine handleEvent: #reset
]
