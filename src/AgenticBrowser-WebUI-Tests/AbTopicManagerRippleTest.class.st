"
I test AbTopicManagerRipple JSON serialization and request/send handling.
"
Class {
	#name : 'AbTopicManagerRippleTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'mockSocket',
		'ripple'
	],
	#category : 'AgenticBrowser-WebUI-Tests',
	#package : 'AgenticBrowser-WebUI-Tests'
}

{ #category : 'running' }
AbTopicManagerRippleTest >> setUp [

	super setUp.
	mockSocket := AbMockWebSocket new token: 'test-session-id'.
	ripple := AbTopicManagerRipple new.
	ripple topicManager: AbTopicManager forTest.
	ripple webSocket: mockSocket
]

{ #category : 'private' }
AbTopicManagerRippleTest >> requestMessage: anAddress body: aBody [

	^ RpMessage new
		  type: 'request';
		  address: anAddress;
		  body: aBody;
		  correlationId: 'corr-1';
		  yourself
]

{ #category : 'private' }
AbTopicManagerRippleTest >> sendMessage: anAddress body: aBody [

	^ RpMessage new
		  type: 'send';
		  address: anAddress;
		  body: aBody;
		  yourself
]

{ #category : 'private' }
AbTopicManagerRippleTest >> messageSends [

	^ mockSocket sentMessages select: [ :m |
		  (m at: 'type') = 'send'
		  and: [ ((m at: 'body') at: 'event') = 'messages' ] ]
]

{ #category : 'private' }
AbTopicManagerRippleTest >> dispatch: aMessage [

	| handler |
	handler := RpWebSocketEventBusHandler new.
	handler rippleClass: AbTopicManagerRipple.
	handler register: mockSocket.
	handler ripples at: mockSocket token put: ripple.
	(RpMessageDispatcher message: aMessage socket: mockSocket handler: handler) dispatch
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTopicAsJsonContainsRequiredFields [

	| topic json |
	topic := self newTopic: 'My Topic'.
	json := ripple topicJson: topic.
	self assert: (json at: 'topicId') equals: topic topicId.
	self assert: (json at: 'title') equals: topic title.
	self assert: (json at: 'status') equals: 'initial'.
	self assert: (json includesKey: 'agentArguments').
	self assert: (json includesKey: 'currentModel').
	self assert: (json includesKey: 'currentMode').
	self assert: (json includesKey: 'lastUpdated')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAsJsonNormalMessage [

	| msg json |
	msg := AbMessage sender: #human text: 'Hello'.
	json := ripple messageJson: msg.
	self assert: (json at: 'sender') equals: 'human'.
	self assert: (json at: 'text') equals: 'Hello'.
	self assert: (json at: 'type') equals: 'normal'.
	self assert: (json at: 'approvalOptions') isEmpty.
	self assert: (json at: 'approvalOption') isNil
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAsJsonThinkMessage [

	| msg json |
	msg := AbMessage sender: #ai text: 'Thinking...' isThink: true.
	json := ripple messageJson: msg.
	self assert: (json at: 'type') equals: 'think'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAsJsonAiPermissionMessage [

	| msg json |
	msg := AbMessage
		       aiPermissionRequestText: 'Allow tool?'
		       options: { 'Allow once' -> #allowOnce. 'Deny' -> #rejectOnce }.
	json := ripple messageJson: msg.
	self assert: (json at: 'type') equals: 'aiPermission'.
	self assert: (json at: 'approvalOptions') size equals: 2.
	self
		assert: ((json at: 'approvalOptions') first at: 'label')
		equals: 'Allow once'.
	self
		assert: ((json at: 'approvalOptions') first at: 'optionId')
		equals: #allowOnce
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testListAgentsRepliesWithAgents [

	| msg agents |
	msg := self requestMessage: '/agents/list' body: nil.
	ripple handleRequest: msg.
	agents := (mockSocket lastReply at: 'body') at: 'agents'.
	self assert: agents isCollection.
	self deny: agents isEmpty.
	self assert: (agents first includesKey: 'name').
	self assert: (agents first includesKey: 'command')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testListTopicsRepliesWithEmptyTopics [

	| msg |
	msg := self requestMessage: '/topics/list' body: nil.
	ripple handleRequest: msg.
	self assert: (mockSocket lastReply at: 'body') equals:
		(Dictionary new at: 'topics' put: #(); yourself)
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testListTopicsRepliesWithAllTopics [

	| topic msg reply |
	topic := self newTopic: 'Alpha'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topics/list' body: nil.
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	self assert: ((reply at: 'body') at: 'topics') size equals: 1.
	self
		assert: (((reply at: 'body') at: 'topics') first at: 'topicId')
		equals: topic topicId
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSelectTopicRepliesOk [

	| topic msg body |
	topic := self newTopic: 'Beta'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/select'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	body := (mockSocket lastReply) at: 'body'.
	self assert: (body at: 'ok')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSelectTopicPushesCurrentViewState [

	| topic msg sends eventNames |
	topic := self newTopic: 'Beta'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/select'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	sends := mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ].
	eventNames := sends collect: [ :m | (m at: 'body') at: 'event' ].
	self assert: (eventNames includes: 'commandsChanged').
	self assert: (eventNames includes: 'modelChanged').
	self assert: (eventNames includes: 'modeChanged')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSelectTopicSignalsErrorForUnknownTopicId [

	| msg |
	msg := self requestMessage: '/topic/select'
		       body: (Dictionary new at: 'topicId' put: 'no-such-id'; yourself).
	self
		should: [ ripple handleRequest: msg ]
		raise: RpError
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCreateTopicAddsToManagerAndRepliesWithTopicId [

	| msg reply topicId |
	msg := self requestMessage: '/topics/create'
		       body: (Dictionary new
			        at: 'title' put: 'New Topic';
			        at: 'agentArguments' put: #( 'claude-agent-acp' );
			        yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	topicId := (reply at: 'body') at: 'topicId'.
	self assert: topicId isString.
	self assert: topicId isNotEmpty.
	self assert: (AbTopicManager forTest at: topicId) isNotNil
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testRenameTopicUpdatesTitle [

	| topic msg reply |
	topic := self newTopic: 'Old Title'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setTitle'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'title' put: 'New Title';
			        yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	self assert: ((reply at: 'body') at: 'ok').
	self assert: topic title equals: 'New Title'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testDeleteTopicRemovesFromManager [

	| topic msg reply |
	topic := self newTopic: 'To Delete'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/delete'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	self assert: ((reply at: 'body') at: 'ok').
	self deny: (AbTopicManager forTest topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetAgentUpdatesAgentArguments [

	| topic msg |
	topic := self newTopic: 'Agent Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setAgent'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'agentArguments' put: #( 'claude-code' );
			        yourself).
	ripple handleRequest: msg.
	self assert: topic agentArguments equals: #( 'claude-code' )
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetGoalSetsGoalOnTopic [

	| topic msg |
	topic := self newMockTopic: 'Goal Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setGoal'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'goal' put: 'Implement feature X';
			        yourself).
	ripple handleRequest: msg.
	self assert: topic topicGoal description equals: 'Implement feature X'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testGetAllMessagesForEmptyTopicSendsDoneChunk [

	| topic msg sends |
	topic := self newTopic: 'Empty'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self sendMessage: '/messages/getAll'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	self dispatch: msg.
	sends := self messageSends.
	self assert: sends size equals: 1.
	self assert: ((sends last at: 'body') at: 'done').
	self assert: ((sends last at: 'body') at: 'messages') isEmpty
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testGetAllMessagesSendsAllMessagesInChunks [

	| topic msg sends allMessages |
	topic := self newTopic: 'With Messages'.
	AbTopicManager forTest addTopic: topic.
	1 to: 25 do: [ :i | topic addSystemMessage: 'Message ' , i printString ].
	mockSocket reset.
	msg := self sendMessage: '/messages/getAll'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	self dispatch: msg.
	sends := self messageSends.
	self assert: ((sends last at: 'body') at: 'done').
	allMessages := sends
		               inject: #()
		               into: [ :acc :s | acc , ((s at: 'body') at: 'messages') ].
	self assert: allMessages size equals: 25
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSendPromptDelegatesToTopic [

	| topic sentText msg |
	sentText := nil.
	topic := self newMockTopic: 'Send Prompt'.
	topic onSendBlock: [ :text :resources | sentText := text ].
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self sendMessage: '/prompt/send'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'text' put: 'Hello';
			        yourself).
	self dispatch: msg.
	self assert: sentText equals: 'Hello'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSendPromptSignalsErrorWhenTopicNotFound [

	| msg |
	msg := self sendMessage: '/prompt/send'
		       body: (Dictionary new
			        at: 'topicId' put: 'no-such-id';
			        at: 'text' put: 'Hello';
			        yourself).
	self dispatch: msg.
	self assert: mockSocket lastError notNil.
	self assert: (mockSocket lastError at: 'error') code equals: 10001
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testResolveApprovalSignalsErrorWhenNoPendingApproval [

	| topic msg |
	topic := self newMockTopic: 'Approve Test'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self sendMessage: '/approval/resolve'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'optionId' put: 'allowOnce';
			        yourself).
	self dispatch: msg.
	self assert: mockSocket lastError notNil.
	self assert: (mockSocket lastError at: 'error') code equals: 10003
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCancelPromptDoesNotRaiseWhenTopicNotWorking [

	| topic msg errorCaught |
	errorCaught := false.
	topic := self newMockTopic: 'Cancel Test'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self sendMessage: '/prompt/cancel'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	[ self dispatch: msg ] on: Error do: [ :e | errorCaught := true ].
	self deny: errorCaught description: 'dispatch: should not propagate errors'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAddedPushesEventToClient [

	| topic pushes |
	topic := self newTopic: 'Push Test'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	topic addSystemMessage: 'system message'.
	pushes := mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ].
	self assert: pushes size equals: 1.
	self assert: ((pushes first at: 'body') at: 'event') equals: 'messageAdded'.
	self
		assert: (((pushes first at: 'body') at: 'message') at: 'text')
		equals: 'system message'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testStatusChangedPushesEventAfterSelectTopic [

	| topic selectMsg pushes |
	topic := self newTopic: 'Status Push'.
	AbTopicManager forTest addTopic: topic.
	selectMsg := self requestMessage: '/topic/select'
		             body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: selectMsg.
	mockSocket reset.
	topic stateMachine handleEvent: #promptSent.
	pushes := mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ].
	self assert: (pushes anySatisfy: [ :p |
		((p at: 'body') at: 'event') = 'statusChanged' ])
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAddedIsBroadcastForAllTopics [

	| topic1 topic2 pushes |
	topic1 := self newTopic: 'Topic 1'.
	topic2 := self newTopic: 'Topic 2'.
	AbTopicManager forTest addTopic: topic1.
	AbTopicManager forTest addTopic: topic2.
	mockSocket reset.
	topic1 addSystemMessage: 'from topic1'.
	topic2 addSystemMessage: 'from topic2'.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'messageAdded' ] ].
	self assert: pushes size equals: 2
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAddedIncludesTopicId [

	| topic msg pushes |
	topic := self newTopic: 'Push Test'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	topic addSystemMessage: 'hello'.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'messageAdded' ] ].
	self assert: pushes size equals: 1.
	self
		assert: ((pushes first at: 'body') at: 'topicId')
		equals: topic topicId
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testUnregisteredUnsubscribesFromTopicManager [

	| topic pushes |
	ripple unregistered.
	topic := self newTopic: 'Post-unregistered topic'.
	AbTopicManager forTest addTopic: topic.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'topicAdded' ] ].
	self assert: pushes isEmpty
		description: 'No topicAdded event should arrive after unregistered'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testUnregisteredUnsubscribesFromAllTopics [

	| topic |
	topic := self newTopic: 'Unregistered Topic'.
	AbTopicManager forTest addTopic: topic.
	ripple unregistered.
	mockSocket reset.
	topic addSystemMessage: 'ignored message'.
	self assert: (mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ]) isEmpty
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTopicAddedIsPushedToClient [

	| topic pushes |
	mockSocket reset.
	topic := self newTopic: 'Pushed Topic'.
	AbTopicManager forTest addTopic: topic.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'topicAdded' ] ].
	self assert: pushes size equals: 1.
	self
		assert: (((pushes first at: 'body') at: 'topic') at: 'topicId')
		equals: topic topicId
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testRoomName [

	self assert: AbTopicManagerRipple roomName equals: 'agentic-browser'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCopyTopicRepliesWithNewTopicId [

	| topic msg reply newTopicId |
	topic := self newTopic: 'Original'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/copy'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	newTopicId := (reply at: 'body') at: 'topicId'.
	self assert: newTopicId isString.
	self assert: newTopicId isNotEmpty.
	self deny: newTopicId = topic topicId
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCopyTopicCreatesNewTopicInManager [

	| topic msg newTopicId |
	topic := self newTopic: 'Original'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/copy'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	newTopicId := ((mockSocket lastReply) at: 'body') at: 'topicId'.
	self assert: (AbTopicManager forTest at: newTopicId) isNotNil.
	self assert: (AbTopicManager forTest at: newTopicId) title equals: '(Copy) ab-test-Original'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCopyTopicSignalsErrorForUnknownTopicId [

	| msg |
	msg := self requestMessage: '/topic/copy'
		       body: (Dictionary new at: 'topicId' put: 'no-such-id'; yourself).
	self should: [ ripple handleRequest: msg ] raise: RpError
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetModelSignalsErrorWhenNoConfigAvailable [

	| topic msg |
	topic := self newTopic: 'Model Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setModel'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'optionId' put: 'claude-sonnet-4-6';
			        yourself).
	[ ripple handleRequest: msg ]
		on: RpError
		do: [ :e | self assert: e code equals: 10007 ]
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetModeSignalsErrorWhenNoConfigAvailable [

	| topic msg |
	topic := self newTopic: 'Mode Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setMode'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'optionId' put: 'ask';
			        yourself).
	[ ripple handleRequest: msg ]
		on: RpError
		do: [ :e | self assert: e code equals: 10008 ]
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetModelRepliesOkAndCallsSetConfigOptionId [

	| topic session mockClient result msg |
	topic := self newMockTopic: 'Model Test'.
	AbTopicManager forTest addTopic: topic.
	session := topic session.
	session updateConfigOptions:
		(OrderedCollection with: (self modelOptionWithCurrentValue: 'claude-sonnet-4-6')).
	result := MockObject new.
	result on: #configOptions verify: [ OrderedCollection new ].
	mockClient := MockObject new.
	mockClient
		on: #setSessionConfigOptionBy:
		with: MockObject any
		verify: [ :aBlock | result ].
	session client: mockClient.
	mockSocket reset.
	msg := self requestMessage: '/topic/setModel'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'optionId' put: 'claude-opus-4-7';
			        yourself).
	ripple handleRequest: msg.
	self assert: ((mockSocket lastReply at: 'body') at: 'ok').
	self verify: mockClient
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetModeRepliesOkAndCallsSetConfigOptionId [

	| topic session mockClient result msg |
	topic := self newMockTopic: 'Mode Test'.
	AbTopicManager forTest addTopic: topic.
	session := topic session.
	session updateConfigOptions:
		(OrderedCollection with: (self modeOptionWithCurrentValue: 'ask')).
	result := MockObject new.
	result on: #configOptions verify: [ OrderedCollection new ].
	mockClient := MockObject new.
	mockClient
		on: #setSessionConfigOptionBy:
		with: MockObject any
		verify: [ :aBlock | result ].
	session client: mockClient.
	mockSocket reset.
	msg := self requestMessage: '/topic/setMode'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'optionId' put: 'code';
			        yourself).
	ripple handleRequest: msg.
	self assert: ((mockSocket lastReply at: 'body') at: 'ok').
	self verify: mockClient
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSaveAppRepliesOk [

	| mockManager msg reply |
	mockManager := AbMockTopicManager new.
	ripple topicManager: mockManager.
	msg := self requestMessage: '/app/save' body: Dictionary new.
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	self assert: ((reply at: 'body') at: 'ok')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSaveAppCallsSaveOnTopicManager [

	| mockManager msg |
	mockManager := AbMockTopicManager new.
	ripple topicManager: mockManager.
	msg := self requestMessage: '/app/save' body: Dictionary new.
	ripple handleRequest: msg.
	self assert: mockManager wasSaved
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTopicAsJsonContainsNameAndGoal [

	| topic json |
	topic := self newTopic: 'Name Goal Test'.
	json := ripple topicJson: topic.
	self assert: (json includesKey: 'name').
	self assert: (json includesKey: 'goal')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAsJsonContainsId [

	| msg json |
	msg := AbMessage sender: #human text: 'Hello'.
	json := ripple messageJson: msg.
	self assert: (json includesKey: 'id').
	self assert: (json at: 'id') isString.
	self assert: (json at: 'id') isNotEmpty
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCreateTopicDefaultsTitleToUntitled [

	| msg reply topicId topic |
	msg := self requestMessage: '/topics/create' body: Dictionary new.
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	topicId := (reply at: 'body') at: 'topicId'.
	topic := AbTopicManager forTest at: topicId.
	self assert: topic title equals: 'Untitled'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCreateTopicPushesTopicAddedEvent [

	| msg pushes |
	mockSocket reset.
	msg := self requestMessage: '/topics/create'
		       body: (Dictionary new
			        at: 'title' put: 'New Topic';
			        at: 'agentArguments' put: #( 'claude-agent-acp' );
			        yourself).
	ripple handleRequest: msg.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'topicAdded' ] ].
	self assert: pushes size equals: 1
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCopyTopicPushesTopicAddedEvent [

	| topic msg pushes |
	topic := self newTopic: 'Original'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/copy'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'topicAdded' ] ].
	self assert: pushes size equals: 1
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetTitlePublishesTopicsUpdated [

	| topic msg publishes |
	topic := self newTopic: 'Old Title'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/setTitle'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'title' put: 'New Title';
			        yourself).
	ripple handleRequest: msg.
	publishes := mockSocket sentMessages select: [ :m |
		             (m at: 'type') = 'publish'
		             and: [ (m at: 'address') = #topicsUpdated ] ].
	self assert: publishes size equals: 1.
	self assert: ((publishes first at: 'body') at: 'event') equals: 'topicsUpdated'.
	self
		assert: ((publishes first at: 'body') at: 'requesterId')
		equals: mockSocket token
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testDeleteTopicPublishesTopicsUpdated [

	| topic msg publishes |
	topic := self newTopic: 'To Delete'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/delete'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	publishes := mockSocket sentMessages select: [ :m |
		             (m at: 'type') = 'publish'
		             and: [ (m at: 'address') = #topicsUpdated ] ].
	self assert: publishes size equals: 1
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetAgentPublishesTopicsUpdated [

	| topic msg publishes |
	topic := self newTopic: 'Agent Topic'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/setAgent'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'agentArguments' put: #( 'claude-code' );
			        yourself).
	ripple handleRequest: msg.
	publishes := mockSocket sentMessages select: [ :m |
		             (m at: 'type') = 'publish'
		             and: [ (m at: 'address') = #topicsUpdated ] ].
	self assert: publishes size equals: 1
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetGoalPublishesTopicsUpdated [

	| topic msg publishes |
	topic := self newMockTopic: 'Goal Topic'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topic/setGoal'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'goal' put: 'Implement feature X';
			        yourself).
	ripple handleRequest: msg.
	publishes := mockSocket sentMessages select: [ :m |
		             (m at: 'type') = 'publish'
		             and: [ (m at: 'address') = #topicsUpdated ] ].
	self assert: publishes size equals: 1
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testDeleteTopicSignalsErrorWhenBusy [

	| topic msg |
	topic := self newTopic: 'Busy Topic'.
	AbTopicManager forTest addTopic: topic.
	topic stateMachine handleEvent: #promptSent.
	msg := self requestMessage: '/topic/delete'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	[ ripple handleRequest: msg ]
		on: RpError
		do: [ :e | self assert: e code equals: 10002 ]
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetAgentSignalsErrorWhenBusy [

	| topic msg |
	topic := self newTopic: 'Busy Topic'.
	AbTopicManager forTest addTopic: topic.
	topic stateMachine handleEvent: #promptSent.
	msg := self requestMessage: '/topic/setAgent'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'agentArguments' put: #( 'claude-code' );
			        yourself).
	[ ripple handleRequest: msg ]
		on: RpError
		do: [ :e | self assert: e code equals: 10002 ]
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testStatusChangedIncludesTopicIdAndStatus [

	| topic statusPush |
	topic := self newTopic: 'Status Body Test'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	topic stateMachine handleEvent: #promptSent.
	statusPush := (mockSocket sentMessages select: [ :m |
		               (m at: 'type') = 'send'
		               and: [ ((m at: 'body') at: 'event') = 'statusChanged' ] ]) first.
	self assert: ((statusPush at: 'body') at: 'topicId') equals: topic topicId.
	self assert: ((statusPush at: 'body') at: 'status') equals: 'working'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testGetAllMessagesSignalsErrorWhenTopicNotFound [

	| msg |
	msg := self sendMessage: '/messages/getAll'
		       body: (Dictionary new at: 'topicId' put: 'no-such-id'; yourself).
	self dispatch: msg.
	self assert: mockSocket lastError notNil.
	self assert: (mockSocket lastError at: 'error') code equals: 10001
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testCancelPromptSignalsErrorWhenTopicNotFound [

	| msg |
	msg := self sendMessage: '/prompt/cancel'
		       body: (Dictionary new at: 'topicId' put: 'no-such-id'; yourself).
	self dispatch: msg.
	self assert: mockSocket lastError notNil.
	self assert: (mockSocket lastError at: 'error') code equals: 10001
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSaveAppSignalsErrorOnSaveFailure [

	| mockManager msg |
	mockManager := AbMockTopicManager new.
	mockManager makeSaveFail.
	ripple topicManager: mockManager.
	msg := self requestMessage: '/app/save' body: Dictionary new.
	[ ripple handleRequest: msg ]
		on: RpError
		do: [ :e | self assert: e code equals: 10006 ]
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testGetSettingsRepliesWithDefaultValues [

	| topic msg reply settings |
	topic := self newTopic: 'Settings Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/getSettings'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	settings := (reply at: 'body') at: 'settings'.
	self assert: (settings includesKey: 'useCommandOnGoalSet').
	self assert: (settings includesKey: 'goalSetCommand').
	self assert: (settings at: 'useCommandOnGoalSet') equals: false.
	self assert: (settings at: 'goalSetCommand') equals: '/goal'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetSettingsUpdatesTopicSettings [

	| topic msg reply |
	topic := self newTopic: 'Settings Test'.
	AbTopicManager forTest addTopic: topic.
	msg := self requestMessage: '/topic/setSettings'
		       body: (Dictionary new
			        at: 'topicId' put: topic topicId;
			        at: 'settings' put: (Dictionary new
				         at: 'useCommandOnGoalSet' put: true;
				         at: 'goalSetCommand' put: '/mygoal';
				         yourself);
			        yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	self assert: ((reply at: 'body') at: 'ok').
	self assert: topic settings useCommandOnGoalSet equals: true.
	self assert: topic settings goalSetCommand equals: '/mygoal'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testGetSettingsSignalsErrorForUnknownTopicId [

	| msg |
	msg := self requestMessage: '/topic/getSettings'
		       body: (Dictionary new at: 'topicId' put: 'no-such-id'; yourself).
	self should: [ ripple handleRequest: msg ] raise: RpError
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSetSettingsSignalsErrorForUnknownTopicId [

	| msg |
	msg := self requestMessage: '/topic/setSettings'
		       body: (Dictionary new
			        at: 'topicId' put: 'no-such-id';
			        at: 'settings' put: Dictionary new;
			        yourself).
	self should: [ ripple handleRequest: msg ] raise: RpError
]
