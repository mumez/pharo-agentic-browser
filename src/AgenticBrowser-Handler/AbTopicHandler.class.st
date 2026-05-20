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

{ #category : 'private' }
AbTopicHandler >> applyApprovalOptionId: anOptionId toResponse: aResponse [

	aResponse selectOptionId: anOptionId asString
]

{ #category : 'accessing' }
AbTopicHandler >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'private' }
AbTopicHandler >> permissionOptionAssociationFor: anACPPermissionOption [

	| label optionId |
	label := anACPPermissionOption name.
	optionId := anACPPermissionOption optionId.
	(label isNil or: [ optionId isNil ]) ifTrue: [ ^ nil ].
	^ label asString -> optionId asSymbol
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
		  'Allow once' -> AbConstants allowOnce.
		  'Always allow' -> AbConstants allowAlways.
		  'Deny' -> AbConstants rejectOnce }
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
AbTopicHandler >> requestPermission: anACPRequestPermission [

	| response approvalOptionId |
	self logger debug: 'requestPermission: ' , anACPRequestPermission printString.
	approvalOptionId := self topic
		                  requestPermission: (self permissionPromptTextFor: anACPRequestPermission)
		                  options: (self permissionOptionsFor: anACPRequestPermission).
	self logger debug: 'requestPermission: got approvalOption='
		, approvalOptionId printString.
	response := anACPRequestPermission makeResponse.
	self applyApprovalOptionId: approvalOptionId toResponse: response.
	^ response
]

{ #category : 'agent-callbacks' }
AbTopicHandler >> sessionUpdate: aSessionUpdate [

	aSessionUpdate isAgentMessageChunk
		ifTrue: [ ^ self topic addAiTextChunk: aSessionUpdate content text ].
	aSessionUpdate isAgentThoughtChunk
		ifTrue: [ ^ self topic addAiThoughtChunk: aSessionUpdate content text ].
	aSessionUpdate isAvailableCommandsUpdate
		ifTrue: [ ^ self topic updateAvailableCommands: aSessionUpdate availableCommands ].
	aSessionUpdate isConfigOptionUpdate
		ifTrue: [ ^ self topic updateCurrentModelFromConfigOptions: aSessionUpdate configOptions ]
]

{ #category : 'accessing' }
AbTopicHandler >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicHandler >> topic: anAbTopic [
	topic := anAbTopic
]
