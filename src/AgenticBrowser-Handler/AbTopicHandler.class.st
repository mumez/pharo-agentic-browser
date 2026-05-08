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

	| response approvalOptionId |
	self logger debug: 'requestPermission: ' , anACPRequestPermission printString.
	approvalOptionId := self topic
		                  requestApproval: (self permissionPromptTextFor: anACPRequestPermission)
		                  options: (self permissionOptionsFor: anACPRequestPermission).
	self logger debug: 'requestPermission: got approvalResponse='
		, approvalOptionId printString.
	response := anACPRequestPermission makeResponse.
	self applyApprovalOptionId: approvalOptionId toResponse: response.
	^ response
]

{ #category : 'private' }
AbTopicHandler >> applyApprovalOptionId: anOptionId toResponse: aResponse [

	| canonicalOptionId |
	canonicalOptionId := self canonicalApprovalOptionId: anOptionId.
	canonicalOptionId = #rejectOnce ifTrue: [
		aResponse rejectOnce.
		^ self ].
	canonicalOptionId = #rejectAlways ifTrue: [
		aResponse rejectAlways.
		^ self ].
	canonicalOptionId = #allowOnce ifTrue: [
		aResponse allowOnce.
		^ self ].
	canonicalOptionId = #allowAlways ifTrue: [
		aResponse allowAlways.
		^ self ].
	aResponse allowOnce
]

{ #category : 'private' }
AbTopicHandler >> canonicalApprovalOptionId: anOptionId [

	| normalized |
	anOptionId ifNil: [ ^ #allowOnce ].
	normalized := anOptionId asString asLowercase.
	normalized := normalized copyReplaceAll: '-' with: '_'.
	normalized := normalized copyReplaceAll: ' ' with: ''.
	normalized = 'allowonce' ifTrue: [ ^ #allowOnce ].
	normalized = 'allow_once' ifTrue: [ ^ #allowOnce ].
	normalized = 'allowalways' ifTrue: [ ^ #allowAlways ].
	normalized = 'allow_always' ifTrue: [ ^ #allowAlways ].
	normalized = 'rejectonce' ifTrue: [ ^ #rejectOnce ].
	normalized = 'reject_once' ifTrue: [ ^ #rejectOnce ].
	normalized = 'rejectalways' ifTrue: [ ^ #rejectAlways ].
	normalized = 'reject_always' ifTrue: [ ^ #rejectAlways ].
	^ normalized asSymbol
]

{ #category : 'private' }
AbTopicHandler >> permissionOptionsFor: anACPRequestPermission [

	| options rawOptions |
	rawOptions := anACPRequestPermission options ifNil: [ #() ].
	options := (rawOptions collect: [ :option |
		            self permissionOptionAssociationFor: option ])
		           reject: [ :assoc | assoc isNil ].
	options ifNotEmpty: [ ^ options asArray ].
	^ {
		  'Allow once' -> #allowOnce.
		  'Always allow' -> #allowAlways.
		  'Deny' -> #rejectOnce }
]

{ #category : 'private' }
AbTopicHandler >> permissionOptionAssociationFor: anACPPermissionOption [

	| label optionId |
	label := anACPPermissionOption name.
	optionId := anACPPermissionOption optionId.
	(label isNil or: [ optionId isNil ]) ifTrue: [ ^ nil ].
	^ label asString -> (self canonicalApprovalOptionId: optionId)
]

{ #category : 'private' }
AbTopicHandler >> permissionPromptTextFor: anACPRequestPermission [

	| toolCall rawInput title packageName |
	toolCall := anACPRequestPermission toolCall.
	rawInput := self rawInputForToolCall: toolCall.
	title := toolCall ifNil: [ nil ] ifNotNil: [
		         toolCall title
			         ifNotNil: [ :v | v asString ]
			         ifNil: [ (rawInput at: 'title' ifAbsent: [ nil ]) ifNotNil: [ :v | v asString ] ] ].
	packageName := (rawInput at: 'package_name' ifAbsent: [ nil ]) ifNotNil: [ :v | v asString ].
	title ifNil: [ ^ 'AI requested permission' ].
	packageName ifNil: [ ^ 'AI requested permission: ' , title ].
	^ 'AI requested permission: ' , title , ' (' , packageName , ')'
]

{ #category : 'private' }
AbTopicHandler >> rawInputForToolCall: anACPToolCall [

	| toolCallDictionary rawInput |
	anACPToolCall ifNil: [ ^ Dictionary new ].
	toolCallDictionary := anACPToolCall asDictionary.
	rawInput := toolCallDictionary at: 'rawInput' ifAbsent: [ Dictionary new ].
	^ rawInput ifNil: [ Dictionary new ]
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
