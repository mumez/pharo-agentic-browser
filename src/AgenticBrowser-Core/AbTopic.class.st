"
I represent a single AI agent conversation session, called a topic.

Responsibility:
- I maintain the conversation history (messages), agent configuration, and FSM lifecycle state.
- I coordinate sending prompts to the agent and handling responses.
- I manage human-in-the-loop approval flows for AI permission and package export requests.
- I track per-topic settings, working directory, and goal completion.

Collaborators:
- AbTopicSession: I delegate ACP client connections and session lifecycle to it.
- AbTopicManager: I am registered and persisted through it.
- AbWorkingDirectory: I manage the filesystem workspace for the agent via it.
- AbTopicRelatedPackagesWatcher: I use it to monitor Pharo image changes.
- AbTopicGoal: I delegate goal-setting and achievement detection to it.
- AbSettings: I hold a per-topic copy of settings, initialized from global defaults.
- AbMessage: I store messages in my conversation history.

Public API and Key Messages:
- #sendPrompt: / #sendPrompt:withResources: - Send a human message and execute the agent.
- #requestPermission: / #requestPermission:options: - Block the agent thread for human approval.
- #resolveApprovalWithOptionId: - Resolve a pending approval from the UI.
- #goalDescription: - Set a goal and notify the agent.
- #status - Return the current FSM state name (#initial, #working, #waitingForHuman, #endTurn, #goalAchieved).

Internal Representation:
- stateMachine - SsStateMachine with 5 states driven by events (#promptSent, #permissionRequested, etc.)
- session - Lazy AbTopicSession; holds the ACP client and config options.
- messages - OrderedCollection of AbMessage; conversation history.
- workingDirectory - Lazy AbWorkingDirectory; manages the agent filesystem workspace.
- topicGoal - Lazy AbTopicGoal; nil until a goal is set.
- settings - Lazy copy of AbSettings.default; per-topic overrides global config.

Implementation Points:
- Approval waits are blocking (poll loop on agent thread); the UI thread is never blocked.
- announcer, logger, workingDirectory, and relatedPackagesWatcher are excluded from Fuel serialization and recreated lazily after load.
- topic name is an alias for title; programmatic lookup via AbTopicManager>>topicsNamed: matches against the title.
"
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
		'session',
		'settings'
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
		msg approvalOption: AbConstants disconnected.
		self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ] ].
	self pendingExportApprovalMessage ifNotNil: [ :msg |
		msg approvalOption: AbConstants disconnected ]
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
		options: AbConstants defaultApprovalOptions
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
		options: AbConstants defaultApprovalOptions
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

{ #category : 'accessing' }
AbTopic >> availableCommands [
	^ self session availableCommands
]

{ #category : 'accessing' }
AbTopic >> availableCommands: aCollection [
	self session availableCommands: aCollection
]

{ #category : 'operations' }
AbTopic >> copyForNewSession [

	| copy |
	copy := self class new.
	copy title: '(Copy) ' , self title.
	copy agentArguments: self agentArguments copy.
	copy workingDirectoryPath: self workingDirectoryPath.
	copy packagePrefixes: self packagePrefixes copy.
	copy settings: (AbSettings new initFrom: self settings).
	self updatedExternalPackageNames do: [ :each |
		copy addUpdatedExternalPackageName: each ].
	^ copy
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
	self topicGoal fireWhenAchieved.
	^ true
]

{ #category : 'operations' }
AbTopic >> whenGoalAchieved: aBlock [
	self topicGoal whenAchieved: aBlock
]

{ #category : 'operations' }
AbTopic >> clearSessionId [

	self disconnect.
	session ifNotNil: [ session clearSessionId ]
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
AbTopic >> currentMode [
	^ self session currentMode
]

{ #category : 'accessing' }
AbTopic >> configOptions [
	^ self session configOptions
]

{ #category : 'accessing' }
AbTopic >> modelConfigOption [
	^ self session modelConfigOption
]

{ #category : 'accessing' }
AbTopic >> modeConfigOption [
	^ self session modeConfigOption
]

{ #category : 'operations' }
AbTopic >> disconnect [

	self session disconnect.
	self abortPendingApprovals
]

{ #category : 'private' }
AbTopic >> ensureWorkingDirectoryForConnection [

	self workingDirectory ensureExists.
	self startWatching.
	^ self workingDirectory path fullName
]

{ #category : 'operations' }
AbTopic >> goalDescription: aString [

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
		  m isApprovalRequest and: [ m approvalOption isNil ] ]
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
	topicGoal := nil.
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
AbTopic >> hasGoal [
	"Reads the raw instance variable, not `self topicGoal`, because that accessor lazily
	creates an empty AbTopicGoal on first read, which would make this always answer true."

	^ topicGoal notNil and: [
		  topicGoal description notNil and: [
			  topicGoal description notEmpty ] ]
]

{ #category : 'testing' }
AbTopic >> isStalled [

	self hasGoal ifFalse: [ ^ false ].
	self isEndTurn ifFalse: [ ^ false ].
	self session isConnected ifFalse: [ ^ false ].
	self topicGoal resultFile exists ifTrue: [ ^ false ].
	self lastUpdated ifNil: [ ^ false ].
	^ (DateAndTime now - self lastUpdated) asSeconds
		  >= self settings goalHavingTopicStallThresholdSeconds
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
AbTopic >> name [
	^ self title
]

{ #category : 'accessing' }
AbTopic >> name: aString [
	self title: aString
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
		detect: [ :m | m isAiPermission and: [ m approvalOption isNil ] ]
		ifNone: [ nil ]
]

{ #category : 'approval-private' }
AbTopic >> pendingApprovalMessage [

	^ self pendingAiPermissionMessage ifNil: [ self pendingExportApprovalMessage ]
]

{ #category : 'approval-private' }
AbTopic >> pendingExportApprovalMessage [

	^ self messages
		detect: [ :m | m isExportApproval and: [ m approvalOption isNil ] ]
		ifNone: [ nil ]
]

{ #category : 'approval-private' }
AbTopic >> respondAiPermissionOnTimeout: aMessage [

	self
		respondOnTimeout: aMessage
		approvalOption: self settings aiPermissionTimeoutOption
		logMessage: 'requestPermission: timeout reached, auto resolving by timeout option'
		changeToHumanResponded: true
]

{ #category : 'approval-private' }
AbTopic >> respondExportOnTimeout: aMessage [

	self
		respondOnTimeout: aMessage
		approvalOption: self settings exportApprovalTimeoutOption
		logMessage: 'requestPackageExport: timeout reached, auto resolving by timeout option'
		changeToHumanResponded: false
]

{ #category : 'approval-private' }
AbTopic >> respondOnTimeout: aMessage approvalOption: anOptionSymbol logMessage: aString changeToHumanResponded: aBoolean [
	aMessage approvalOption ifNotNil: [ ^ self ].
	self logger debug: aString.
	aMessage approvalOption: anOptionSymbol.
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

	| msg responseOnTime |
	self logger debug: 'requestPackageExport: waiting for human. description=' , aDescription printString.
	msg := self addExportApprovalRequest: aDescription options: AbConstants defaultApprovalOptions.
	responseOnTime := self waitForExportApprovalOf: msg.
	responseOnTime ifNil: [self respondExportOnTimeout: msg].
	self logger debug: 'requestPackageExport: done. response=' , msg approvalOption printString.
	^ msg approvalOption
]

{ #category : 'operations' }
AbTopic >> requestPermission: aDescription [

	^ self requestPermission: aDescription options: AbConstants defaultApprovalOptions
]

{ #category : 'operations' }
AbTopic >> requestPermission: aDescription options: approvalOptions [

	| msg responseOnTime |
	self logger debug: 'requestPermission: waiting for human. description=' , aDescription printString.
	msg := self addAiPermissionRequestAndWaitForHuman: aDescription options: approvalOptions.
	responseOnTime := self waitForAiPermissionOf: msg.
	responseOnTime ifNil: [self respondAiPermissionOnTimeout: msg].
	self logger debug: 'requestPermission: done. response=' , msg approvalOption printString.
	^ msg approvalOption
]

{ #category : 'operations' }
AbTopic >> resetFromGoalAchieved [

	self stateMachine handleEvent: #reset
]

{ #category : 'operations' }
AbTopic >> resolveApprovalWithOptionId: anOptionId [

	| pending |
	pending := self pendingApprovalMessage.
	pending ifNil: [ ^ self ].
	pending approvalOption: anOptionId.
	self isWaitingForHuman ifTrue: [ self stateMachine handleEvent: #humanResponded ].
	self logger debug: 'resolveApproval: status(after humanResponded)=' , self status printString.
	self logger debug: 'resolveApproval: done'
]

{ #category : 'operations' }
AbTopic >> registerTo: aTopicManager [
	aTopicManager addTopic: self
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
	self executePrompt: aString withResources: aCollection
]

{ #category : 'accessing' }
AbTopic >> session [
	^ session ifNil: [ session := AbTopicSession on: self ]
]

{ #category : 'accessing' }
AbTopic >> session: aSession [
	session := aSession
]

{ #category : 'accessing' }
AbTopic >> sessionId [
	^ self session sessionId
]

{ #category : 'private' }
AbTopic >> addErrorSystemMessage: aString [

	self logger error: aString.
	self addSystemMessage: aString
]

{ #category : 'private' }
AbTopic >> acpRequestErrorTextFrom: anACPRequestError [

	^ String streamContents: [ :strm |
		strm << anACPRequestError messageText.
		anACPRequestError code ifNotNil: [ :code |
			strm << (' (code: {1})' format: { code }) ].
		anACPRequestError data ifNotNil: [ :data |
			strm << (' (data: {1})' format: { data }) ] ]
]

{ #category : 'private' }
AbTopic >> doExecutePrompt: aString withResources: aCollection [

	[[ self trySendPrompt: aString withResources: aCollection ]
		on: NetworkError
		do: [ :netEx | self handleNetworkError: netEx ] ]
	on: ACPRequestError
	do: [ :acpEx | self handleAcpRequestError: acpEx ]
]

{ #category : 'error handling' }
AbTopic >> handleNetworkError: aNetworkError [

	self addErrorSystemMessage: aNetworkError description.
	self stateMachine handleEvent: #turnEnded
]

{ #category : 'error handling' }
AbTopic >> handleAcpRequestError: anACPRequestError [

	self addErrorSystemMessage: (self acpRequestErrorTextFrom: anACPRequestError).
	self stateMachine handleEvent: #turnEnded
]

{ #category : 'private' }
AbTopic >> trySendPrompt: aString withResources: aCollection [

	| result |
	self session ensureConnected.
	result := self client promptBy: [ :params |
		params sessionId: self sessionId.
		params textPrompt: aString.
		aCollection do: [ :resource | resource applyToPromptParams: params ] ].
	result stopReason = 'end_turn' ifTrue: [
		self checkGoalAchievement ifFalse: [
			self stateMachine handleEvent: #turnEnded ] ]
]

{ #category : 'private' }
AbTopic >> executePrompt: aString withResources: aCollection [

	[ self doExecutePrompt: aString withResources: aCollection ] fork
]

{ #category : 'accessing' }
AbTopic >> settings [

	^ settings ifNil: [ settings := AbSettings defaultCopied ]
]

{ #category : 'accessing' }
AbTopic >> settings: anAbSettings [
	settings := anAbSettings
]

{ #category : 'operations' }
AbTopic >> startWatching [

	self workingDirectory subscribeToSisServerImportEvents.
	self relatedPackagesWatcher isWatching ifFalse: [ self relatedPackagesWatcher start ]
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

	self relatedPackagesWatcherIfPresent ifNotNil: [ :watcher | watcher stop ].
	self workingDirectory unsubscribeFromSisServerImportEvents
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
	^ topicGoal ifNil: [ topicGoal := AbTopicGoal on: self ]
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
AbTopic >> updateConfigOptions: aCollection [

	self session updateConfigOptions: aCollection
]

{ #category : 'operations' }
AbTopic >> setConfigOptionId: aConfigId value: aValue [

	self session setConfigOptionId: aConfigId value: aValue
]

{ #category : 'accessing' }
AbTopic >> updatedExternalPackageNames [
	^ updatedExternalPackageNames
]

{ #category : 'approval-private' }
AbTopic >> waitForAiPermissionOf: aMessage [

	^ self
		waitForApprovalOf: aMessage
		timeoutSeconds: self settings aiPermissionWaitTimeoutSeconds
]

{ #category : 'approval-private' }
AbTopic >> waitForApprovalOf: aMessage timeoutSeconds: timeoutSeconds [

	| waitSeconds |
	waitSeconds := 0.
	[ aMessage approvalOption isNil and: [ waitSeconds < timeoutSeconds ] ] whileTrue: [
		1 second wait.
		waitSeconds := waitSeconds + 1 ].
	^ aMessage approvalOption
]

{ #category : 'approval-private' }
AbTopic >> waitForExportApprovalOf: aMessage [

	^ self
		waitForApprovalOf: aMessage
		timeoutSeconds: self settings exportApprovalWaitTimeoutSeconds
]

{ #category : 'accessing' }
AbTopic >> workingDirectory [

	^ workingDirectory ifNil: [ workingDirectory := AbWorkingDirectory forTopic: self ]
]

{ #category : 'accessing' }
AbTopic >> workingDirectoryPath [

	^ workingDirectoryPath ifNil: [ workingDirectoryPath := self workingDirectory defaultPath ]
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
