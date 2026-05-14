Class {
	#name : 'AbTopic',
	#superclass : 'Object',
	#instVars : [
		'title',
		'agentArguments',
		'messages',
		'stateMachine',
		'announcer',
		'topicId',
		'packagePrefixes',
		'updatedExternalPackageNames',
		'workingDirectory',
		'relatedPackagesWatcher',
		'workingDirectoryPath',
		'logger',
		'topicGoal',
		'session'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'fuel' }
AbTopic class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' 'logger' 'workingDirectory' 'relatedPackagesWatcher' )
]

{ #category : 'approval-private' }
AbTopic >> abortPendingApprovals [

	self pendingAiPermissionMessage ifNotNil: [ :msg |
		msg approvalResponse: AbConstants disconnected.
		self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ] ].
	self pendingExportApprovalMessage ifNotNil: [ :msg |
		msg approvalResponse: AbConstants disconnected ]
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
AbTopic >> addAiPermissionRequest: aDescription [

	^ self
		addAiPermissionRequest: aDescription
		options: AbConstants defaultApprovalOptions copy
]

{ #category : 'approval-private' }
AbTopic >> addAiPermissionRequest: aDescription options: approvalOptions [

	| msg |
	msg := AbMessage
		       aiPermissionRequestText: aDescription
		       options: approvalOptions.
	self messages add: msg.
	self announceMessageAdded: msg.
	^ msg
]

{ #category : 'approval-private' }
AbTopic >> addAiPermissionRequestAndWaitForHuman: aDescription options: approvalOptions [

	| msg |
	msg := self addAiPermissionRequest: aDescription options: approvalOptions.
	self stateMachine handleEvent: #permissionRequested.
	self logger debug: 'addAiPermissionRequest: status(after permissionRequested)='
		, self status printString.
	^ msg
]

{ #category : 'operations' }
AbTopic >> addAiTextChunk: aString [

	self addAiChunk: aString think: false
]

{ #category : 'operations' }
AbTopic >> addAiThoughtChunk: aString [

	self addAiChunk: aString think: true
]

{ #category : 'operations' }
AbTopic >> addExportApprovalRequest: aDescription [

	^ self
		addExportApprovalRequest: aDescription
		options: AbConstants defaultApprovalOptions copy
]

{ #category : 'approval-private' }
AbTopic >> addExportApprovalRequest: aDescription options: approvalOptions [

	| msg |
	msg := AbMessage
		       exportApprovalRequestText: aDescription
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
AbTopic >> addSystemMessage: aString [

	| msg |
	msg := AbMessage sender: #system text: aString.
	self messages add: msg.
	self announceMessageAdded: msg
]

{ #category : 'operations' }
AbTopic >> addUpdatedExternalPackageName: aString [

	self updatedExternalPackageNames add: aString
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
AbTopic >> announceGoalAchieved [

	self announcer announce: (AbTopicGoalAchieved new
			 topic: self;
			 goal: self topicGoal;
			 yourself)
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

{ #category : 'private' }
AbTopic >> approvalResponseForUserText: aUserText [

	^ (aUserText trimmed asLowercase includesSubstring: 'no')
		  | (aUserText trimmed asLowercase includesSubstring: 'deny')
		  | (aUserText trimmed asLowercase includesSubstring: 'reject')
			ifTrue: [ AbConstants rejectOnce ]
			ifFalse: [ AbConstants allowOnce ]
]

{ #category : 'accessing' }
AbTopic >> availableCommands [
	^ self session availableCommands
]

{ #category : 'accessing' }
AbTopic >> availableCommands: aCollection [
	self session availableCommands: aCollection
]

{ #category : 'operations' }
AbTopic >> cancelPrompt [

	self isWorking ifFalse: [ ^ self ].
	self client ifNotNil: [
		self client cancelBy: [ :params | params sessionId: self sessionId ] ].
	self stateMachine handleEvent: #turnEnded
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

{ #category : 'operations' }
AbTopic >> clearSessionId [

	self disconnect.
	self session clearSessionId
]

{ #category : 'operations' }
AbTopic >> clearUpdatedExternalPackageNames [

	self updatedExternalPackageNames removeAll
]

{ #category : 'accessing' }
AbTopic >> client [
	^ self session client
]

{ #category : 'accessing' }
AbTopic >> currentModel [
	^ self session currentModel
]

{ #category : 'accessing' }
AbTopic >> defaultWorkingDirectoryPath [

	^ (Smalltalk imageDirectory / 'agentic-browser'
	   / self workingDirectory directoryName) fullName
]

{ #category : 'operations' }
AbTopic >> disconnect [

	self session disconnect.
	self abortPendingApprovals
]

{ #category : 'private' }
AbTopic >> ensureWorkingDirectoryForConnection [

	self workingDirectory ensureExists.
	self workingDirectory subscribeToSisServerImportEvents.
	self relatedPackagesWatcher isWatching ifFalse: [ self startWatching ].
	^ self workingDirectory path fullName
]

{ #category : 'operations' }
AbTopic >> goalDescription: aString [

	self topicGoal: (AbTopicGoal on: self).
	self topicGoal description: aString.
	self sendPrompt: self topicGoal notificationPrompt
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

{ #category : 'initialization' }
AbTopic >> initialize [

	title := 'Untitled'.
	agentArguments := #( 'claude-agent-acp' ).
	messages := OrderedCollection new.
	packagePrefixes := Set new.
	updatedExternalPackageNames := Set new.
	session := nil.
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

{ #category : 'testing' }
AbTopic >> isEndTurn [

	^ self status = #endTurn
]

{ #category : 'testing' }
AbTopic >> isGoalAchieved [

	^ self status = #goalAchieved
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

{ #category : 'accessing' }
AbTopic >> lastUpdated [

	self messages ifEmpty: [ ^ nil ].
	^ self messages
		  inject: self messages first lastUpdated
		  into: [ :latest :each | latest max: each lastUpdated ]
]

{ #category : 'accessing' }
AbTopic >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
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
AbTopic >> packagePrefixes [
	^ packagePrefixes
]

{ #category : 'accessing' }
AbTopic >> packagePrefixes: aCollection [
	packagePrefixes := aCollection asSet
]

{ #category : 'approval-private' }
AbTopic >> pendingAiPermissionMessage [

	^ self messages
		detect: [ :m | m isAiPermission and: [ m approvalResponse isNil ] ]
		ifNone: [ nil ]
]

{ #category : 'approval-private' }
AbTopic >> pendingApprovalMessage [

	^ self pendingAiPermissionMessage ifNil: [ self pendingExportApprovalMessage ]
]

{ #category : 'approval-private' }
AbTopic >> pendingExportApprovalMessage [

	^ self messages
		detect: [ :m | m isExportApproval and: [ m approvalResponse isNil ] ]
		ifNone: [ nil ]
]

{ #category : 'approval-private' }
AbTopic >> rejectAiPermissionOnTimeout: aMessage [

	self
		rejectOnTimeout: aMessage
		logMessage: 'requestPermission: timeout reached, auto rejecting'
		transitionHumanIfWaiting: true
]

{ #category : 'approval-private' }
AbTopic >> rejectExportOnTimeout: aMessage [

	self
		rejectOnTimeout: aMessage
		logMessage: 'requestPackageExport: timeout reached, auto rejecting'
		transitionHumanIfWaiting: false
]

{ #category : 'approval-private' }
AbTopic >> rejectOnTimeout: aMessage logMessage: aString transitionHumanIfWaiting: aBoolean [

	aMessage approvalResponse ifNotNil: [ ^ self ].
	self logger debug: aString.
	aMessage approvalResponse: AbConstants rejectOnce.
	(aBoolean and: [ self isWaitingForHuman ]) ifTrue: [
		self stateMachine handleEvent: #humanResponded ]
]

{ #category : 'accessing' }
AbTopic >> relatedPackagesWatcher [

	^ relatedPackagesWatcher ifNil: [ relatedPackagesWatcher := AbTopicRelatedPackagesWatcher forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> relatedPackagesWatcherIfPresent [

	^ relatedPackagesWatcher
]

{ #category : 'operations' }
AbTopic >> removePackagePrefix: aString [

	self packagePrefixes remove: aString ifAbsent: []
]

{ #category : 'operations' }
AbTopic >> requestPackageExport: aDescription [

	| msg |
	self logger debug: 'requestPackageExport: waiting for human. description=' , aDescription printString.
	msg := self addExportApprovalRequest: aDescription options: AbConstants defaultApprovalOptions copy.
	self waitForExportApprovalOf: msg.
	self rejectExportOnTimeout: msg.
	self logger debug: 'requestPackageExport: done. response=' , msg approvalResponse printString.
	^ msg approvalResponse ifNil: [ AbConstants rejectOnce ]
]

{ #category : 'operations' }
AbTopic >> requestPermission: aDescription [

	^ self requestPermission: aDescription options: AbConstants defaultApprovalOptions copy
]

{ #category : 'operations' }
AbTopic >> requestPermission: aDescription options: approvalOptions [

	| msg |
	self logger debug: 'requestPermission: waiting for human. description=' , aDescription printString.
	msg := self addAiPermissionRequestAndWaitForHuman: aDescription options: approvalOptions.
	self waitForAiPermissionOf: msg.
	self rejectAiPermissionOnTimeout: msg.
	self logger debug: 'requestPermission: done. response=' , msg approvalResponse printString.
	^ msg approvalResponse ifNil: [ AbConstants rejectOnce ]
]

{ #category : 'operations' }
AbTopic >> resetFromGoalAchieved [

	self stateMachine handleEvent: #reset
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
	self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ].
	self logger debug: 'resolveApproval: status(after humanResponded)=' , self status printString.
	self logger debug: 'resolveApproval: done'
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString [

	self sendPrompt: aString withResources: #()
]

{ #category : 'operations' }
AbTopic >> sendPrompt: aString withResources: aCollection [

	| msg |
	msg := AbMessage sender: #human text: aString.
	self messages add: msg.
	self announceMessageAdded: msg.
	self stateMachine handleEvent: #promptSent.
	[
	| result |
	self session ensureConnected.
		result := self client promptBy: [ :params |
				  params sessionId: self sessionId.
				  params textPrompt: aString.
				  aCollection do: [ :assoc |
				      params resourcePrompt: assoc key text: assoc value ] ].
		result stopReason = 'end_turn' ifTrue: [
			self checkGoalAchievement ifFalse: [
				self stateMachine handleEvent: #turnEnded ] ] ] fork
]

{ #category : 'accessing' }
AbTopic >> session [
	^ session ifNil: [ session := AbTopicSession on: self ]
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ self session sessionId
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
AbTopic >> topicGoal [
	^ topicGoal
]

{ #category : 'accessing' }
AbTopic >> topicGoal: anAbTopicGoal [
	topicGoal := anAbTopicGoal
]

{ #category : 'accessing' }
AbTopic >> topicId [
	^ topicId
]

{ #category : 'operations' }
AbTopic >> updateAvailableCommands: aCollection [

	self session updateAvailableCommands: aCollection
]

{ #category : 'operations' }
AbTopic >> updateCurrentModelFromConfigOptions: aCollection [

	self session updateCurrentModelFromConfigOptions: aCollection
]

{ #category : 'accessing' }
AbTopic >> updatedExternalPackageNames [
	^ updatedExternalPackageNames
]

{ #category : 'approval-private' }
AbTopic >> waitForAiPermissionOf: aMessage [

	^ self
		waitForApprovalOf: aMessage
		timeoutSeconds: AbSettings default aiPermissionWaitTimeoutSeconds
]

{ #category : 'approval-private' }
AbTopic >> waitForApprovalOf: aMessage timeoutSeconds: timeoutSeconds [

	| waitSeconds |
	waitSeconds := 0.
	[ aMessage approvalResponse isNil and: [ waitSeconds < timeoutSeconds ] ] whileTrue: [
		1 second wait.
		waitSeconds := waitSeconds + 1 ].
	^ aMessage approvalResponse
]

{ #category : 'approval-private' }
AbTopic >> waitForExportApprovalOf: aMessage [

	^ self
		waitForApprovalOf: aMessage
		timeoutSeconds: AbSettings default exportApprovalWaitTimeoutSeconds
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
