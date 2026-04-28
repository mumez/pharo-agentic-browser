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

	| response approvalResponse |
	approvalResponse := topic requestApproval: anACPRequestPermission printString.
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
		ifTrue: [ ^ topic addAiTextChunk: aSessionUpdate content text ].
	aSessionUpdate isAgentThoughtChunk
		ifTrue: [ ^ topic addAiThoughtChunk: aSessionUpdate content text ]
]

{ #category : 'accessing' }
AbTopicHandler >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicHandler >> topic: anAbTopic [
	topic := anAbTopic
]
