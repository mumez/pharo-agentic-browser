Class {
	#name : 'AbMockTopicNoPromptSend',
	#superclass : 'AbMockTopic',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'initialize-release' }
AbMockTopicNoPromptSend >> initialize [

	super initialize.
	self session client
		on: #promptBy:
		respond: (ACPPromptResponse fromDictionary: { 'stopReason' -> 'end_turn' } asDictionary)
]
