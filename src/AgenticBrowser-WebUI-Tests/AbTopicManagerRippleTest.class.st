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

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTopicAsJsonContainsRequiredFields [

	| topic json |
	topic := self newTopic: 'My Topic'.
	json := ripple topicAsJson: topic.
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
	json := ripple messageAsJson: msg.
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
	json := ripple messageAsJson: msg.
	self assert: (json at: 'type') equals: 'think'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAsJsonAiPermissionMessage [

	| msg json |
	msg := AbMessage
		       aiPermissionRequestText: 'Allow tool?'
		       options: { 'Allow once' -> #allowOnce. 'Deny' -> #rejectOnce }.
	json := ripple messageAsJson: msg.
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
AbTopicManagerRippleTest >> testSelectTopicRepliesOkWithConfig [

	| topic msg reply body |
	topic := self newTopic: 'Beta'.
	AbTopicManager forTest addTopic: topic.
	mockSocket reset.
	msg := self requestMessage: '/topics/select'
		       body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: msg.
	reply := mockSocket lastReply.
	body := reply at: 'body'.
	self assert: (body at: 'ok').
	self assert: (body includesKey: 'availableCommands').
	self assert: (body includesKey: 'modelOptions').
	self assert: (body includesKey: 'modeOptions')
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSelectTopicSignalsErrorForUnknownTopicId [

	| msg |
	msg := self requestMessage: '/topics/select'
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
	msg := self requestMessage: '/topics/rename'
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
	msg := self requestMessage: '/topics/delete'
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
	msg := self requestMessage: '/topics/setAgent'
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
	msg := self requestMessage: '/topics/setGoal'
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
	ripple handleSend: msg.
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
	ripple handleSend: msg.
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
	ripple handleSend: msg.
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
	ripple handleSend: msg.
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
	ripple handleSend: msg.
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
	[ ripple handleSend: msg ] on: Error do: [ :e | errorCaught := true ].
	self deny: errorCaught description: 'handleSend: should not propagate errors'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testMessageAddedPushesEventAfterSelectTopic [

	| topic selectMsg pushes |
	topic := self newTopic: 'Push Test'.
	AbTopicManager forTest addTopic: topic.
	selectMsg := self requestMessage: '/topics/select'
		             body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: selectMsg.
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
	selectMsg := self requestMessage: '/topics/select'
		             body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: selectMsg.
	mockSocket reset.
	topic stateMachine handleEvent: #promptSent.
	pushes := mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ].
	self assert: (pushes anySatisfy: [ :p |
		((p at: 'body') at: 'event') = 'statusChanged' ])
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testSelectTopicReplacesExistingSubscription [

	| topic1 topic2 selectMsg1 selectMsg2 pushes |
	topic1 := self newTopic: 'Topic 1'.
	topic2 := self newTopic: 'Topic 2'.
	AbTopicManager forTest addTopic: topic1.
	AbTopicManager forTest addTopic: topic2.
	selectMsg1 := self requestMessage: '/topics/select'
		              body: (Dictionary new at: 'topicId' put: topic1 topicId; yourself).
	selectMsg2 := self requestMessage: '/topics/select'
		              body: (Dictionary new at: 'topicId' put: topic2 topicId; yourself).
	ripple handleRequest: selectMsg1.
	ripple handleRequest: selectMsg2.
	mockSocket reset.
	topic1 addSystemMessage: 'from topic1'.
	topic2 addSystemMessage: 'from topic2'.
	pushes := mockSocket sentMessages select: [ :m | (m at: 'type') = 'send' ].
	self assert: pushes size equals: 1.
	self
		assert: (((pushes first at: 'body') at: 'message') at: 'text')
		equals: 'from topic2'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTeardownUnsubscribesFromTopicManager [

	| topic pushes |
	ripple teardown.
	topic := self newTopic: 'Post-teardown topic'.
	AbTopicManager forTest addTopic: topic.
	pushes := mockSocket sentMessages select: [ :m |
		          (m at: 'type') = 'send'
		          and: [ ((m at: 'body') at: 'event') = 'topicAdded' ] ].
	self assert: pushes isEmpty
		description: 'No topicAdded event should arrive after teardown'
]

{ #category : 'tests' }
AbTopicManagerRippleTest >> testTeardownUnsubscribesFromSubscribedTopic [

	| topic selectMsg |
	topic := self newTopic: 'Teardown Topic'.
	AbTopicManager forTest addTopic: topic.
	selectMsg := self requestMessage: '/topics/select'
		             body: (Dictionary new at: 'topicId' put: topic topicId; yourself).
	ripple handleRequest: selectMsg.
	ripple teardown.
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
