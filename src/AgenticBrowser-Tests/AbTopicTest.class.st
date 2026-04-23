Class {
	#name : 'AbTopicTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicTest >> testInitialStatus [

	self assert: AbTopic new status equals: #idle
]

{ #category : 'tests' }
AbTopicTest >> testPromptSentTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testHumanRespondedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	topic stateMachine handleEvent: #humanResponded.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testEndedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #ended.
	self assert: topic status equals: #done
]

{ #category : 'tests' }
AbTopicTest >> testDoneToWorkingOnNewPrompt [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #ended.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalAllowAlways [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	topic messages add: msg.
	topic resolveApproval: 'yes'.
	self assert: msg approvalResponse equals: #allowAlways.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalRejectOnce [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I delete files?'.
	topic messages add: msg.
	topic resolveApproval: 'no'.
	self assert: msg approvalResponse equals: #rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkCreatesMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Hello'
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkAppendsToExistingAiMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	topic addAiTextChunk: ' world'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last text equals: 'Hello world'
]

{ #category : 'tests' }
AbTopicTest >> testAddApprovalRequestAddsMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addApprovalRequest: 'May I delete files?'.
	self assert: topic messages size equals: 1.
	self assert: msg isApprovalRequest.
	self assert: msg approvalSemaphore notNil
]

{ #category : 'tests' }
AbTopicTest >> testStatusChangedAnnouncementFired [

	| topic statusChanges |
	topic := AbTopic new.
	statusChanges := OrderedCollection new.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | statusChanges add: ann topic status ]
		for: self.
	topic stateMachine handleEvent: #promptSent.
	self assert: (statusChanges includes: #working)
]
