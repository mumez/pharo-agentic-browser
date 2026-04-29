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
	self assert: msg timestamp notNil
]

{ #category : 'tests' }
AbMessageTest >> testAppendText [

	| msg |
	msg := AbMessage sender: #ai text: 'Starting '.
	msg appendText: 'work...'.
	self assert: msg text equals: 'Starting work...'
]

{ #category : 'tests' }
AbMessageTest >> testApprovalRequestCreation [

	| msg |
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	self assert: msg sender equals: #ai.
	self assert: msg text equals: 'May I modify DBAdapter?'.
	self assert: msg isApprovalRequest.
	self assert: msg approvalResponse isNil
]

{ #category : 'tests' }
AbMessageTest >> testDisplayStringAi [

	| msg |
	msg := AbMessage sender: #ai text: 'Hello'.
	self assert: (msg displayText includesSubstring: 'AI')
]

{ #category : 'tests' }
AbMessageTest >> testDisplayStringHuman [

	| msg |
	msg := AbMessage sender: #human text: 'Hello'.
	self assert: (msg displayText includesSubstring: 'Human')
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
	msg := AbMessage sender: #ai text: 'Let me think...' think: true.
	self assert: msg sender equals: #ai.
	self assert: msg text equals: 'Let me think...'.
	self assert: msg isThink.
	self assert: (msg displayText includesSubstring: 'AI(think)')
]

{ #category : 'tests' }
AbMessageTest >> testDisplayStringAiThink [

	| msg |
	msg := AbMessage sender: #ai text: 'Planning steps' think: true.
	self assert: msg displayText equals: '[AI(think)] Planning steps'
]
