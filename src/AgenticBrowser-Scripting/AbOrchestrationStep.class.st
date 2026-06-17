Class {
	#name : 'AbOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'topicBuilders',
		'agentConfig',
		'sharedDirectoryPath',
		'previousResult'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbOrchestrationStep >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbOrchestrationStep >> orchestration: anOrchestration [
	orchestration := anOrchestration
]

{ #category : 'accessing' }
AbOrchestrationStep >> topicBuilders [
	^ topicBuilders
]

{ #category : 'accessing' }
AbOrchestrationStep >> topicBuilders: aCollection [
	topicBuilders := aCollection
]

{ #category : 'accessing' }
AbOrchestrationStep >> agentConfig [
	^ agentConfig
]

{ #category : 'accessing' }
AbOrchestrationStep >> agentConfig: anAgentConfig [
	agentConfig := anAgentConfig
]

{ #category : 'accessing' }
AbOrchestrationStep >> sharedDirectoryPath [
	^ sharedDirectoryPath
]

{ #category : 'accessing' }
AbOrchestrationStep >> sharedDirectoryPath: aString [
	sharedDirectoryPath := aString
]

{ #category : 'accessing' }
AbOrchestrationStep >> activeAgentConfig [
	^ agentConfig ifNil: [ orchestration defaultAgentConfig ]
]

{ #category : 'accessing' }
AbOrchestrationStep >> previousResult [
	^ previousResult
]

{ #category : 'accessing' }
AbOrchestrationStep >> previousResult: aString [
	previousResult := aString
]

{ #category : 'running' }
AbOrchestrationStep >> run [
	self subclassResponsibility
]

{ #category : 'private' }
AbOrchestrationStep >> combinedResultsFrom: aCollectionOfTopics [
	| results |
	results := aCollectionOfTopics collect: [ :topic | self resultFromTopic: topic ].
	results := results reject: #isNil.
	results isEmpty ifTrue: [ ^ nil ].
	^ results joinUsing: String crlf , String crlf
]

{ #category : 'private' }
AbOrchestrationStep >> promptForBuilder: aBuilder topic: aTopic injecting: aPreviousResult [
	| prompt |
	prompt := aBuilder prompt ifNil: [ aTopic title ].
	aPreviousResult ifNil: [ ^ prompt ].
	^ String streamContents: [ :strm |
		strm << prompt.
		strm crlf; crlf.
		strm << '=== Previous Topic Result ==='; crlf.
		strm << aPreviousResult ]
]

{ #category : 'private' }
AbOrchestrationStep >> resultFromTopic: aTopic [
	^ aTopic topicGoal isAchieved
		ifTrue: [ aTopic topicGoal result ]
		ifFalse: [
			(aTopic messages notEmpty and: [ aTopic messages last sender = #ai ])
				ifTrue: [ aTopic messages last text ]
				ifFalse: [ nil ] ]
]
