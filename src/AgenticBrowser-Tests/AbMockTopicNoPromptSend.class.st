Class {
	#name : 'AbMockTopicNoPromptSend',
	#superclass : 'AbMockTopic',
	#instVars : [
		'sendBlock'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'initialize-release' }
AbMockTopicNoPromptSend >> initialize [

	super initialize.
	self session client
		on: #promptBy:
		verify: [ :paramsBlock |
			ACPPromptResponse fromDictionary: { 'stopReason' -> 'end_turn' } asDictionary ]
]

{ #category : 'accessing' }
AbMockTopicNoPromptSend >> onSendBlock: aBlock [

	sendBlock := aBlock
]

{ #category : 'operations' }
AbMockTopicNoPromptSend >> sendPrompt: aString withResources: aCollection [

	sendBlock ifNotNil: [ sendBlock value: aString value: aCollection ].
	super sendPrompt: aString withResources: aCollection
]

{ #category : 'private' }
AbMockTopicNoPromptSend >> trySendPrompt: aString withResources: aCollection [
	self checkGoalAchievement ifFalse: [
		self stateMachine handleEvent: #turnEnded ]
]
