Class {
	#name : 'AbTopicHandler',
	#superclass : 'ACPClientHandler',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Handler',
	#package : 'AgenticBrowser-Handler'
}

{ #category : 'agent-callbacks' }
AbTopicHandler >> requestPermission: anACPRequestPermission [

	| msg response |
	msg := topic addApprovalRequest: anACPRequestPermission printString.
	topic stateMachine handleEvent: #permissionRequested.
	msg approvalSemaphore wait.
	response := anACPRequestPermission makeResponse.
	msg approvalResponse = #rejectOnce ifTrue: [
		response rejectOnce.
		^ response ].
	msg approvalResponse = #rejectAlways ifTrue: [
		response rejectAlways.
		^ response ].
	response allowAlways.
	^ response
]

{ #category : 'agent-callbacks' }
AbTopicHandler >> sessionUpdate: aSessionUpdate [

	(aSessionUpdate isAgentMessageChunk or: [ aSessionUpdate isAgentThoughtChunk ])
		ifFalse: [ ^ self ].
	topic addAiTextChunk: aSessionUpdate content text
]

{ #category : 'accessing' }
AbTopicHandler >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicHandler >> topic: anAbTopic [
	topic := anAbTopic
]
