Class {
	#name : 'AbMessageTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbMessageTest >> testAiMessageCreation [

	| msg |
	msg := AbMessage sender: #ai text: 'Working on it'.
	self assert: msg sender equals: #ai.
	self assert: msg lastUpdated notNil
]

{ #category : 'tests' }
AbMessageTest >> testAppendText [

	| msg before |
	msg := AbMessage sender: #ai text: 'Starting '.
	before := msg lastUpdated.
	(Delay forMilliseconds: 1) wait.
	msg appendText: 'work...'.
	self assert: msg text equals: 'Starting work...'.
	self assert: msg lastUpdated > before
]

{ #category : 'tests' }
AbMessageTest >> testTextUpdateRefreshesLastUpdated [

	| msg before |
	msg := AbMessage sender: #ai text: 'Draft'.
	before := msg lastUpdated.
	(Delay forMilliseconds: 1) wait.
	msg text: 'Final'.
	self assert: msg text equals: 'Final'.
	self assert: msg lastUpdated > before
]

{ #category : 'tests' }
AbMessageTest >> testApprovalRequestCreation [

	| msg |
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	self assert: msg sender equals: #ai.
	self assert: msg text equals: 'May I modify DBAdapter?'.
	self assert: msg isApprovalRequest.
	self assert: msg approvalOptions isEmpty.
	self assert: msg approvalResponse isNil
]

{ #category : 'tests' }
AbMessageTest >> testApprovalRequestCreationWithOptions [

	| options msg |
	options := OrderedCollection
		           with: ('Allow once' -> #allow_once)
		           with: ('Deny' -> #reject_once).
	msg := AbMessage
		       approvalRequestText: 'Select permission option'
		       options: options.
	self assert: msg isApprovalRequest.
	self assert: msg approvalOptions equals: options
]

{ #category : 'tests' }
AbMessageTest >> testPrintStringIncludesSender [

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	self assert: (msg printString includesSubstring: 'ai')
]

{ #category : 'tests' }
AbMessageTest >> testPrintStringIncludesText [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	self assert: (msg printString includesSubstring: 'Hello')
]

{ #category : 'tests' }
AbMessageTest >> testHumanMessageCreation [

	| msg |
	msg := AbMessage sender: #human text: 'Fix the N+1 issue'.
	self assert: msg sender equals: #human.
	self assert: msg text equals: 'Fix the N+1 issue'.
	self deny: msg isApprovalRequest.
]

{ #category : 'tests' }
AbMessageTest >> testThinkMessageCreation [

	| msg |
	msg := AbMessage sender: #ai text: 'Let me think...' isThink: true.
	self assert: msg sender equals: #ai.
	self assert: msg text equals: 'Let me think...'.
	self assert: msg isThink.
]
