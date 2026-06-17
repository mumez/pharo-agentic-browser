"
I am the Ripple WebSocket endpoint for the Agentic Browser web UI.

Responsibility:
- I handle one WebSocket client connection per instance.
- I dispatch request messages to reply handlers (/topics/list, /topics/select, etc.).
- I dispatch send messages to one-way handlers (/messages/getAll, /prompt/send, etc.).
- I push real-time topic events (messageAdded, statusChanged, etc.) to the client via server-send.
- I subscribe to ALL events for ALL topics at connect time and when new topics are added.
  All connected clients receive messageAdded, statusChanged, modelChanged, modeChanged,
  commandsChanged, and topicAdded for every topic (broadcast model).

Public API and Key Messages:
- AbTopicManagerRipple class>>roomName - 'agentic-browser' room identifier
- AbTopicManagerRipple class>>startWebUIServer - Start RpServer and register this room
- #topicManager: - Inject a test AbTopicManager (defaults to AbTopicManager default)
- #webSocket: - Sets socket and activates AbTopicManager subscription (call after topicManager:)
- #unregistered - Unsubscribes all announcer subscriptions (called by RpWebSocketBaseHandler on disconnect)

Internal Representation:
- topicManager - The AbTopicManager used; defaults to AbTopicManager default
"
Class {
	#name : 'AbTopicManagerRipple',
	#superclass : 'RpRipple',
	#instVars : [
		'topicManager'
	],
	#category : 'AgenticBrowser-WebUI',
	#package : 'AgenticBrowser-WebUI'
}

{ #category : 'actions' }
AbTopicManagerRipple class >> startWebUIServer [
	<script>
	RpServer default start.
	self putRouteToDefaultServer
]


{ #category : 'accessing' }
AbTopicManagerRipple class >> roomName [

	^ 'agentic-browser'
]

{ #category : 'accessing' }
AbTopicManagerRipple >> topicManager [

	^ topicManager ifNil: [ topicManager := AbTopicManager default ]
]

{ #category : 'accessing' }
AbTopicManagerRipple >> topicManager: aManager [

	topicManager := aManager
]

{ #category : 'accessing' }
AbTopicManagerRipple >> webSocket: aWebSocket [

	super webSocket: aWebSocket.
	self subscribeToTopicManager
]

{ #category : 'private' }
AbTopicManagerRipple >> subscribeToTopicManager [

	self topicManager announcer
		when: AbTopicAdded
		do: [ :ann | self onTopicAdded: ann topic ]
		for: self.
	self topicManager topics do: [ :each | self subscribeToTopic: each ]
]

{ #category : 'private' }
AbTopicManagerRipple >> subscribeToTopic: aTopic [

	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self onStatusChanged: ann ]
		for: self.
	aTopic announcer
		when: AbMessageAdded
		do: [ :ann | self onMessageAdded: ann ]
		for: self.
	aTopic announcer
		when: AbTopicCurrentModelChanged
		do: [ :ann | self onModelChanged: ann ]
		for: self.
	aTopic announcer
		when: AbTopicCurrentModeChanged
		do: [ :ann | self onModeChanged: ann ]
		for: self.
	aTopic announcer
		when: AbTopicAvailableCommandsChanged
		do: [ :ann | self onCommandsChanged: ann ]
		for: self
]

{ #category : 'lifecycle' }
AbTopicManagerRipple >> unregistered [

	super unregistered.
	self topicManager announcer unsubscribe: self.
	self topicManager topics do: [ :each | each announcer unsubscribe: self ]
]

{ #category : 'private' }
AbTopicManagerRipple >> topicNotFoundError: aTopicId [

	^ (RpError application: 'Topic not found: ' , aTopicId code: 10001) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> topicBusyError: aTopicId [

	^ (RpError application: 'Topic is busy: ' , aTopicId code: 10002) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> noPendingApprovalError: aTopicId [

	^ (RpError application: 'No pending approval for topic: ' , aTopicId code: 10003) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> invalidOptionError: anOptionId [

	^ (RpError application: 'Invalid optionId: ' , anOptionId printString code: 10004) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> createTopicFailedError: aReason [

	^ (RpError application: 'Failed to create topic: ' , aReason code: 10005) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> saveFailedError: aReason [

	^ (RpError application: 'Failed to save: ' , aReason code: 10006) signal
]

{ #category : 'json' }
AbTopicManagerRipple >> topicJson: aTopic [

	^ Dictionary new
		  at: 'topicId' put: aTopic topicId;
		  at: 'title' put: aTopic title;
		  at: 'name' put: (aTopic name ifNil: [ '' ]);
		  at: 'status' put: aTopic status asString;
		  at: 'agentArguments' put: aTopic agentArguments;
		  at: 'goal' put: (aTopic topicGoal description ifNil: [ '' ]);
		  at: 'currentModel' put: (aTopic currentModel ifNil: [ '' ]);
		  at: 'currentMode' put: (aTopic currentMode ifNil: [ '' ]);
		  at: 'lastUpdated' put: (aTopic lastUpdated ifNil: [ '' ] ifNotNil: [ :d | d printString ]);
		  yourself
]

{ #category : 'json' }
AbTopicManagerRipple >> messageJson: aMessage [

	| type |
	type := aMessage isThink
		        ifTrue: [ 'think' ]
		        ifFalse: [
			        aMessage isAiPermission
				        ifTrue: [ 'aiPermission' ]
				        ifFalse: [
					        aMessage isExportApproval
						        ifTrue: [ 'exportApproval' ]
						        ifFalse: [ 'normal' ] ] ].
	^ Dictionary new
		  at: 'id' put: aMessage id;
		  at: 'sender' put: aMessage sender asString;
		  at: 'text' put: aMessage text;
		  at: 'type' put: type;
		  at: 'approvalOptions' put: (self approvalOptionsJson: aMessage approvalOptions);
		  at: 'approvalOption' put: aMessage approvalOption;
		  at: 'lastUpdated' put: (aMessage lastUpdated ifNil: [ '' ] ifNotNil: [ :d | d printString ]);
		  yourself
]

{ #category : 'json' }
AbTopicManagerRipple >> approvalOptionsJson: aCollectionOrNil [

	aCollectionOrNil ifNil: [ ^ #() ].
	^ aCollectionOrNil asArray collect: [ :assoc |
		  Dictionary new
			  at: 'label' put: assoc key;
			  at: 'optionId' put: assoc value;
			  yourself ]
]

{ #category : 'json' }
AbTopicManagerRipple >> modelOptionsJson: aTopic [

	^ aTopic modelConfigOption ifNotNil: [ :opt | opt asDictionary ]
]

{ #category : 'json' }
AbTopicManagerRipple >> modeOptionsJson: aTopic [

	^ aTopic modeConfigOption ifNotNil: [ :opt | opt asDictionary ]
]

{ #category : 'json' }
AbTopicManagerRipple >> commandsJson: aTopic [

	^ aTopic availableCommands ifNil: [ #() ] ifNotNil: [ :cmds |
		  cmds collect: [ :cmd | cmd asDictionary ] ]
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleRequest: aMessage [

	aMessage address = '/agents/list' ifTrue: [ ^ self handleListAgents: aMessage ].
	aMessage address = '/topics/list' ifTrue: [ ^ self handleListTopics: aMessage ].
	aMessage address = '/topics/create' ifTrue: [ ^ self handleCreateTopic: aMessage ].
	aMessage address = '/topic/setTitle' ifTrue: [ ^ self handleRenameTopic: aMessage ].
	aMessage address = '/topic/delete' ifTrue: [ ^ self handleDeleteTopic: aMessage ].
	aMessage address = '/topic/setAgent' ifTrue: [ ^ self handleSetAgent: aMessage ].
	aMessage address = '/topic/setGoal' ifTrue: [ ^ self handleSetGoal: aMessage ].
	aMessage address = '/topic/setModel' ifTrue: [ ^ self handleSetModel: aMessage ].
	aMessage address = '/topic/setMode' ifTrue: [ ^ self handleSetMode: aMessage ].
	aMessage address = '/topic/copy' ifTrue: [ ^ self handleCopyTopic: aMessage ].
	aMessage address = '/topic/select' ifTrue: [ ^ self handleSelectTopic: aMessage ].
	aMessage address = '/topic/getSettings' ifTrue: [ ^ self handleGetSettings: aMessage ].
	aMessage address = '/topic/setSettings' ifTrue: [ ^ self handleSetSettings: aMessage ].
	aMessage address = '/app/save' ifTrue: [ ^ self handleSaveApp: aMessage ].
	(RpError general: 'Unknown address: ' , aMessage address) signal
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleListAgents: aMessage [

	self webSocket
		sendReply: (Dictionary new at: 'agents' put: AbSettings default codingAgents; yourself)
		for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleListTopics: aMessage [

	| topicsJson |
	topicsJson := self topicManager topics collect: [ :t | self topicJson: t ].
	self webSocket
		sendReply: (Dictionary new at: 'topics' put: topicsJson asArray; yourself)
		for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleCreateTopic: aMessage [

	| body topic |
	body := aMessage body.
	[ topic := AbTopic new.
	topic title: (body at: 'title' ifAbsent: [ 'Untitled' ]).
	(body at: 'agentArguments' ifAbsent: [ nil ]) ifNotNil: [ :args |
		topic agentArguments: args asArray ].
	self topicManager addTopic: topic ]
		on: Error
		do: [ :e | self createTopicFailedError: e messageText ].
	self webSocket
		sendReply: (Dictionary new at: 'topicId' put: topic topicId; yourself)
		for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleRenameTopic: aMessage [

	| body topicId topic |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic title: (body at: 'title').
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage.
	self publishTopicsUpdated
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleDeleteTopic: aMessage [

	| topicId topic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic isWorking ifTrue: [ self topicBusyError: topicId ].
	self topicManager removeTopic: topic.
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage.
	self publishTopicsUpdated
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleGetSettings: aMessage [

	| topicId topic settings |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	settings := topic settings.
	self webSocket
		sendReply: (Dictionary new
			at: 'settings' put: (Dictionary new
				at: 'useCommandOnGoalSet' put: settings useCommandOnGoalSet;
				at: 'goalSetCommand' put: settings goalSetCommand;
				yourself);
			yourself)
		for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetSettings: aMessage [

	| body topicId topic settings |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	settings := body at: 'settings'.
	(settings includesKey: 'useCommandOnGoalSet') ifTrue: [
		topic settings useCommandOnGoalSet: (settings at: 'useCommandOnGoalSet') ].
	(settings includesKey: 'goalSetCommand') ifTrue: [
		topic settings goalSetCommand: (settings at: 'goalSetCommand') ].
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetAgent: aMessage [

	| body topicId topic |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic isWorking ifTrue: [ self topicBusyError: topicId ].
	topic agentArguments: (body at: 'agentArguments') asArray.
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage.
	self publishTopicsUpdated
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetGoal: aMessage [

	| body topicId topic |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic goalDescription: (body at: 'goal').
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage.
	self publishTopicsUpdated
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetModel: aMessage [

	self
		applyConfigOption: [ :t | t modelConfigOption ]
		from: aMessage
		noConfigError: 10007
		label: 'model'
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetMode: aMessage [

	self
		applyConfigOption: [ :t | t modeConfigOption ]
		from: aMessage
		noConfigError: 10008
		label: 'mode'
]

{ #category : 'private' }
AbTopicManagerRipple >> applyConfigOption: aBlock from: aMessage noConfigError: anErrorCode label: aLabel [

	| body topicId topic configOption |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	configOption := aBlock value: topic.
	configOption ifNil: [
		^ (RpError application: 'No ' , aLabel , ' config available for: ' , topicId code: anErrorCode) signal ].
	topic setConfigOptionId: configOption id value: (body at: 'optionId').
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleCopyTopic: aMessage [

	| topicId topic newTopic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	newTopic := topic copyForNewSession.
	self topicManager addTopic: newTopic.
	self webSocket
		sendReply: (Dictionary new at: 'topicId' put: newTopic topicId; yourself)
		for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSaveApp: aMessage [

	[ self topicManager save ]
		on: Error
		do: [ :e | self saveFailedError: e messageText ].
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSelectTopic: aMessage [

	| topicId topic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	self webSocket
		sendReply: (Dictionary new at: 'ok' put: true; yourself)
		for: aMessage.
	self pushCurrentTopicViewState: topic
]

{ #category : 'request handling' }
AbTopicManagerRipple >> pushCurrentTopicViewState: aTopic [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'commandsChanged';
		 at: 'topicId' put: aTopic topicId;
		 at: 'commands' put: (self commandsJson: aTopic);
		 yourself).
	self pushToClient: (Dictionary new
		 at: 'event' put: 'modelChanged';
		 at: 'topicId' put: aTopic topicId;
		 at: 'options' put: (self modelOptionsJson: aTopic);
		 yourself).
	self pushToClient: (Dictionary new
		 at: 'event' put: 'modeChanged';
		 at: 'topicId' put: aTopic topicId;
		 at: 'options' put: (self modeOptionsJson: aTopic);
		 yourself)
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleSend: aMessage [

	aMessage address = '/messages/getAll' ifTrue: [ ^ self handleGetAllMessages: aMessage ].
	aMessage address = '/prompt/send' ifTrue: [ ^ self handleSendPrompt: aMessage ].
	aMessage address = '/prompt/cancel' ifTrue: [ ^ self handleCancelPrompt: aMessage ].
	aMessage address = '/approval/resolve' ifTrue: [ ^ self handleResolveApproval: aMessage ].
	(RpError general: 'Unknown address: ' , aMessage address) signal
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleGetAllMessages: aMessage [

	| topicId topic chunkSize messages |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	chunkSize := 20.
	messages := topic messages asArray.
	messages
		ifEmpty: [
			self pushToClient: (Dictionary new
				 at: 'event' put: 'messages';
				 at: 'messages' put: #();
				 at: 'done' put: true;
				 yourself) ].
	messages ifNotEmpty: [
		1 to: messages size by: chunkSize do: [ :start |
		| chunk done |
		chunk := messages copyFrom: start to: (start + chunkSize - 1 min: messages size).
		done := (start + chunkSize - 1) >= messages size.
		self pushToClient: (Dictionary new
			 at: 'event' put: 'messages';
			 at: 'messages' put: (chunk collect: [ :m | self messageJson: m ]);
			 at: 'done' put: done;
			 yourself) ] ]
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleSendPrompt: aMessage [

	| body topicId topic text |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	text := body at: 'text'.
	topic sendPrompt: text
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleCancelPrompt: aMessage [

	| topicId topic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic cancelPrompt
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleResolveApproval: aMessage [

	| body topicId topic optionId pending |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	pending := topic pendingApprovalMessage.
	pending ifNil: [ self noPendingApprovalError: topicId ].
	optionId := (body at: 'optionId') asSymbol.
	(pending approvalOptions anySatisfy: [ :assoc | assoc value = optionId ])
		ifFalse: [ self invalidOptionError: optionId ].
	topic resolveApprovalWithOptionId: optionId
]

{ #category : 'private' }
AbTopicManagerRipple >> logger [

	^ AbLocalLogger new
]

{ #category : 'private' }
AbTopicManagerRipple >> pushToClient: aBody [

	[ self send: aBody to: #serverEventPushed ]
		on: Error
		do: [ :e |
			self logger warn: { self class name. #pushToClient. e messageText }.
			self unregistered ]
]

{ #category : 'private' }
AbTopicManagerRipple >> publishTopicsUpdated [

	self publish: (Dictionary new
		 at: 'event' put: 'topicsUpdated';
		 at: 'requesterId' put: self webSocket token;
		 yourself) to: #topicsUpdated
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onTopicAdded: aTopic [

	self subscribeToTopic: aTopic.
	self pushToClient: (Dictionary new
		 at: 'event' put: 'topicAdded';
		 at: 'topic' put: (self topicJson: aTopic);
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onMessageAdded: ann [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'messageAdded';
		 at: 'topicId' put: ann topic topicId;
		 at: 'message' put: (self messageJson: ann message);
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onStatusChanged: ann [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'statusChanged';
		 at: 'topicId' put: ann topic topicId;
		 at: 'status' put: ann status asString;
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onModelChanged: ann [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'modelChanged';
		 at: 'topicId' put: ann topic topicId;
		 at: 'options' put: (self modelOptionsJson: ann topic);
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onModeChanged: ann [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'modeChanged';
		 at: 'topicId' put: ann topic topicId;
		 at: 'options' put: (self modeOptionsJson: ann topic);
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onCommandsChanged: ann [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'commandsChanged';
		 at: 'topicId' put: ann topic topicId;
		 at: 'commands'
		 put: (ann commands
			  ifNil: [ #() ]
			  ifNotNil: [ :cmds | cmds collect: [ :cmd | cmd asDictionary ] ]);
		 yourself)
]
