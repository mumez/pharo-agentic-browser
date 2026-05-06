Class {
	#name : 'AbTopicHandler',
	#superclass : 'ACPClientHandler',
	#instVars : [
		'topic',
		'logger'
	],
	#category : 'AgenticBrowser-Handler',
	#package : 'AgenticBrowser-Handler'
}

{ #category : 'agent-callbacks' }
AbTopicHandler >> requestPermission: anACPRequestPermission [

	| response approvalResponse |
	self logger debug: 'requestPermission: ' , anACPRequestPermission printString.
	approvalResponse := self topic requestApproval: anACPRequestPermission printString.
	self logger debug: 'requestPermission: got approvalResponse=' , approvalResponse printString.
	response := anACPRequestPermission makeResponse.
	approvalResponse = #rejectOnce ifTrue: [
		response rejectOnce.
		^ response ].
	approvalResponse = #rejectAlways ifTrue: [
		response rejectAlways.
		^ response ].
	response allowAlways.
	^ response
]

{ #category : 'agent-callbacks' }
AbTopicHandler >> sessionUpdate: aSessionUpdate [

	aSessionUpdate isAgentMessageChunk
		ifTrue: [ ^ self topic addAiTextChunk: aSessionUpdate content text ].
	aSessionUpdate isAgentThoughtChunk
		ifTrue: [ ^ self topic addAiThoughtChunk: aSessionUpdate content text ].
	aSessionUpdate isAvailableCommandsUpdate
		ifTrue: [ ^ self topic updateAvailableCommands: aSessionUpdate availableCommands ]
]

{ #category : 'accessing' }
AbTopicHandler >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbTopicHandler >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicHandler >> topic: anAbTopic [
	topic := anAbTopic
]
