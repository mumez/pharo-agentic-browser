Class {
	#name : 'AbTopicSessionTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicSessionTest >> testOnCreatesSessionWithTopicBackReference [

	| topic session |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	self assert: session topic equals: topic
]

{ #category : 'tests' }
AbTopicSessionTest >> testOnInitializesTransientFields [

	| topic session |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	self assert: session sessionId isNil.
	self assert: session currentModel isNil.
	self assert: session availableCommands isEmpty
]

{ #category : 'tests' }
AbTopicSessionTest >> testDisconnectClearsTransientFields [

	| topic session mockClient |
	topic := AbTopic new.
	session := AbTopicSession on: topic.
	mockClient := MockObject new.
	mockClient on: #disconnect verify: [ ].
	session client: mockClient.
	session sessionId: 'session-1'.
	session currentModel: 'claude-opus-4'.
	session availableCommands: (OrderedCollection
			 with: (ACPAvailableCommand new rawValues: (Dictionary new
					  at: 'name' put: '/help';
					  at: 'description' put: 'Show help';
					  yourself))).

	session disconnect.

	self verify: mockClient.
	self assert: session client isNil.
	self assert: session sessionId isNil.
	self assert: session currentModel isNil.
	self assert: session availableCommands isEmpty
]
