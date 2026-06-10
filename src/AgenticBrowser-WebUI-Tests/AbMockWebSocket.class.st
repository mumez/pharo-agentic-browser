"
I am a test double for RpWebSocket.
I capture all messages sent through me for assertion in tests.
"
Class {
	#name : 'AbMockWebSocket',
	#superclass : 'Object',
	#instVars : [
		'token',
		'sentMessages'
	],
	#category : 'AgenticBrowser-WebUI-Tests',
	#package : 'AgenticBrowser-WebUI-Tests'
}

{ #category : 'initialization' }
AbMockWebSocket >> initialize [

	sentMessages := OrderedCollection new
]

{ #category : 'accessing' }
AbMockWebSocket >> token [

	^ token
]

{ #category : 'accessing' }
AbMockWebSocket >> token: aString [

	token := aString
]

{ #category : 'accessing' }
AbMockWebSocket >> sentMessages [

	^ sentMessages
]

{ #category : 'sending' }
AbMockWebSocket >> sendReply: body for: msg [

	sentMessages add: (Dictionary new
		 at: 'type' put: 'reply';
		 at: 'body' put: body;
		 at: 'correlationId' put: msg correlationId;
		 yourself)
]

{ #category : 'sending' }
AbMockWebSocket >> send: body to: address [

	sentMessages add: (Dictionary new
		 at: 'type' put: 'send';
		 at: 'address' put: address;
		 at: 'body' put: body;
		 yourself)
]

{ #category : 'sending' }
AbMockWebSocket >> sendError: anError for: msg [

	sentMessages add: (Dictionary new
		 at: 'type' put: 'err';
		 at: 'error' put: anError;
		 yourself)
]

{ #category : 'testing' }
AbMockWebSocket >> reset [

	sentMessages := OrderedCollection new
]

{ #category : 'testing' }
AbMockWebSocket >> lastReply [

	^ (sentMessages select: [ :m | (m at: 'type') = 'reply' ]) last
]

{ #category : 'testing' }
AbMockWebSocket >> lastSend [

	^ (sentMessages select: [ :m | (m at: 'type') = 'send' ]) last
]

{ #category : 'testing' }
AbMockWebSocket >> lastError [

	^ (sentMessages select: [ :m | (m at: 'type') = 'err' ]) last
]
