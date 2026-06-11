"
I am the Ripple WebSocket endpoint for the Agentic Browser web UI.

Responsibility:
- I handle one WebSocket client connection per instance.
- I dispatch request messages to reply handlers (/topics/list, /topics/select, etc.).
- I dispatch send messages to one-way handlers (/messages/getAll, /prompt/send, etc.).
- I push real-time topic events (messageAdded, statusChanged, etc.) to the client via server-send.
- I subscribe to AbTopicManager announcer to broadcast topicAdded events.
- I subscribe to every topic's AbTopicStatusChanged at connect (broadcast scope).

Public API and Key Messages:
- AbTopicManagerRipple class>>roomName - 'agentic-browser' room identifier
- AbTopicManagerRipple class>>startWebUIServer - Start RpServer and register this room
- #topicManager: - Inject a test AbTopicManager (defaults to AbTopicManager default)
- #webSocket: - Sets socket and activates AbTopicManager subscription (call after topicManager:)
- #unregistered - Unsubscribes all announcer subscriptions (called by RpWebSocketBaseHandler on disconnect)

Internal Representation:
- subscribedTopic - AbTopic currently watched by this client; nil if none selected
- topicManager - The AbTopicManager used; defaults to AbTopicManager default
"
Class {
	#name : 'AbTopicManagerRipple',
	#superclass : 'RpRipple',
	#instVars : [
		'subscribedTopic',
		'topicManager'
	],
	#category : 'AgenticBrowser-WebUI',
	#package : 'AgenticBrowser-WebUI'
}

{ #category : 'actions' }
AbTopicManagerRipple class >> startWebUIServer [
	<script>
	RpServer createStarted.
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
AbTopicManagerRipple >> subscribedTopic [

	^ subscribedTopic
]

{ #category : 'accessing' }
AbTopicManagerRipple >> subscribedTopic: aTopic [

	subscribedTopic := aTopic
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
	self topicManager topics do: [ :each | self subscribeToTopicStatus: each ]
]

{ #category : 'private' }
AbTopicManagerRipple >> subscribeToTopicStatus: aTopic [

	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann | self onStatusChanged: ann ]
		for: self
]

{ #category : 'private' }
AbTopicManagerRipple >> subscribeToTopicView: aTopic [

	self subscribedTopic ifNotNil: [ :old |
		old announcer unsubscribe: self class ].
	self subscribedTopic: aTopic.
	aTopic announcer
		when: AbMessageAdded
		do: [ :ann | self onMessageAdded: ann message ]
		for: self class.
	aTopic announcer
		when: AbTopicCurrentModelChanged
		do: [ :ann | self onModelChanged: ann ]
		for: self class.
	aTopic announcer
		when: AbTopicCurrentModeChanged
		do: [ :ann | self onModeChanged: ann ]
		for: self class.
	aTopic announcer
		when: AbTopicAvailableCommandsChanged
		do: [ :ann | self onCommandsChanged: ann ]
		for: self class
]

{ #category : 'lifecycle' }
AbTopicManagerRipple >> unregistered [

	super unregistered.
	self topicManager announcer unsubscribe: self.
	self topicManager topics do: [ :each | each announcer unsubscribe: self ].
	self subscribedTopic ifNotNil: [ :t |
		t announcer unsubscribe: self class ].
	self subscribedTopic: nil
]

{ #category : 'private' }
AbTopicManagerRipple >> topicNotFoundError: aTopicId [

	^ (RpError code: 10001 type: 'application' message: 'Topic not found: ' , aTopicId) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> topicBusyError: aTopicId [

	^ (RpError code: 10002 type: 'application' message: 'Topic is busy: ' , aTopicId) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> noPendingApprovalError: aTopicId [

	^ (RpError code: 10003 type: 'application' message: 'No pending approval for topic: ' , aTopicId) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> invalidOptionError: anOptionId [

	^ (RpError code: 10004 type: 'application' message: 'Invalid optionId: ' , anOptionId printString) signal
]

{ #category : 'private' }
AbTopicManagerRipple >> createTopicFailedError: aReason [

	^ (RpError code: 10005 type: 'application' message: 'Failed to create topic: ' , aReason) signal
]

{ #category : 'json' }
AbTopicManagerRipple >> topicAsJson: aTopic [

	^ Dictionary new
		  at: 'topicId' put: aTopic topicId;
		  at: 'title' put: aTopic title;
		  at: 'name' put: (aTopic name ifNil: [ '' ]);
		  at: 'status' put: aTopic status asString;
		  at: 'agentArguments' put: aTopic agentArguments;
		  at: 'currentModel' put: (aTopic currentModel ifNil: [ '' ]);
		  at: 'currentMode' put: (aTopic currentMode ifNil: [ '' ]);
		  at: 'lastUpdated' put: (aTopic lastUpdated ifNil: [ '' ] ifNotNil: [ :d | d printString ]);
		  yourself
]

{ #category : 'json' }
AbTopicManagerRipple >> messageAsJson: aMessage [

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
AbTopicManagerRipple >> optionsJsonFrom: aConfigOption [

	| raw options currentValue |
	raw := aConfigOption rawValues.
	currentValue := raw at: 'currentValue' ifAbsent: [ '' ].
	options := raw at: 'options' ifAbsent: [ #() ].
	^ options collect: [ :opt |
		  Dictionary new
			  at: 'label' put: (opt at: 'name' ifAbsent: [ '' ]);
			  at: 'optionId' put: (opt at: 'value' ifAbsent: [ '' ]);
			  at: 'selected' put: ((opt at: 'value' ifAbsent: [ '' ]) = currentValue);
			  yourself ]
]

{ #category : 'json' }
AbTopicManagerRipple >> modelOptionsJson: aTopic [

	^ aTopic modelConfigOption
		ifNil: [ #() ]
		ifNotNil: [ :opt | self optionsJsonFrom: opt ]
]

{ #category : 'json' }
AbTopicManagerRipple >> modeOptionsJson: aTopic [

	^ aTopic modeConfigOption
		ifNil: [ #() ]
		ifNotNil: [ :opt | self optionsJsonFrom: opt ]
]

{ #category : 'json' }
AbTopicManagerRipple >> commandsJson: aTopic [

	^ aTopic availableCommands ifNil: [ #() ] ifNotNil: [ :cmds |
		  cmds collect: [ :cmd |
			  Dictionary new
				  at: 'label' put: cmd name;
				  at: 'optionId' put: cmd name;
				  at: 'selected' put: false;
				  yourself ] ]
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleRequest: aMessage [

	aMessage address = '/agents/list' ifTrue: [ ^ self handleListAgents: aMessage ].
	aMessage address = '/topics/list' ifTrue: [ ^ self handleListTopics: aMessage ].
	aMessage address = '/topics/create' ifTrue: [ ^ self handleCreateTopic: aMessage ].
	aMessage address = '/topics/setTitle' ifTrue: [ ^ self handleRenameTopic: aMessage ].
	aMessage address = '/topics/delete' ifTrue: [ ^ self handleDeleteTopic: aMessage ].
	aMessage address = '/topics/setAgent' ifTrue: [ ^ self handleSetAgent: aMessage ].
	aMessage address = '/topics/setGoal' ifTrue: [ ^ self handleSetGoal: aMessage ].
	aMessage address = '/topics/select' ifTrue: [ ^ self handleSelectTopic: aMessage ].
	(RpError code: 0 type: 'general' message: 'Unknown address: ' , aMessage address) signal
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
	topicsJson := self topicManager topics collect: [ :t | self topicAsJson: t ].
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
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleDeleteTopic: aMessage [

	| topicId topic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic isWorking ifTrue: [ self topicBusyError: topicId ].
	self topicManager removeTopic: topic.
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
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSetGoal: aMessage [

	| body topicId topic |
	body := aMessage body.
	topicId := body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	topic goalDescription: (body at: 'goal').
	self webSocket sendReply: (Dictionary new at: 'ok' put: true; yourself) for: aMessage
]

{ #category : 'request handling' }
AbTopicManagerRipple >> handleSelectTopic: aMessage [

	| topicId topic |
	topicId := aMessage body at: 'topicId'.
	topic := self topicManager at: topicId.
	topic ifNil: [ self topicNotFoundError: topicId ].
	self subscribeToTopicView: topic.
	self webSocket
		sendReply: (Dictionary new
			 at: 'ok' put: true;
			 at: 'availableCommands' put: (self commandsJson: topic);
			 at: 'modelOptions' put: (self modelOptionsJson: topic);
			 at: 'modeOptions' put: (self modeOptionsJson: topic);
			 yourself)
		for: aMessage
]

{ #category : 'send handling' }
AbTopicManagerRipple >> handleSend: aMessage [

	aMessage address = '/messages/getAll' ifTrue: [ ^ self handleGetAllMessages: aMessage ].
	aMessage address = '/prompt/send' ifTrue: [ ^ self handleSendPrompt: aMessage ].
	aMessage address = '/prompt/cancel' ifTrue: [ ^ self handleCancelPrompt: aMessage ].
	aMessage address = '/approval/resolve' ifTrue: [ ^ self handleResolveApproval: aMessage ].
	(RpError code: 0 type: 'general' message: 'Unknown address: ' , aMessage address) signal
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
			 at: 'messages' put: (chunk collect: [ :m | self messageAsJson: m ]);
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

	[ self webSocket send: aBody to: self webSocket token ]
		on: Error
		do: [ :e |
			self logger warn: { self class name. #pushToClient. e messageText }.
			self unregistered ]
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onTopicAdded: aTopic [

	self subscribeToTopicStatus: aTopic.
	self pushToClient: (Dictionary new
		 at: 'event' put: 'topicAdded';
		 at: 'topic' put: (self topicAsJson: aTopic);
		 yourself)
]

{ #category : 'topic events' }
AbTopicManagerRipple >> onMessageAdded: aMessage [

	self pushToClient: (Dictionary new
		 at: 'event' put: 'messageAdded';
		 at: 'message' put: (self messageAsJson: aMessage);
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
			  ifNotNil: [ :cmds |
				  cmds collect: [ :cmd |
					  Dictionary new
						  at: 'label' put: cmd name;
						  at: 'optionId' put: cmd name;
						  at: 'selected' put: false;
						  yourself ] ]);
		 yourself)
]
