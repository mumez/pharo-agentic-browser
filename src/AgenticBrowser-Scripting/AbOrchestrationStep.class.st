Class {
	#name : 'AbOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'topicBuilders',
		'codingAgentBuilder',
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
AbOrchestrationStep >> codingAgentBuilder [
	^ codingAgentBuilder
]

{ #category : 'accessing' }
AbOrchestrationStep >> codingAgentBuilder: anCodingAgentBuilder [
	codingAgentBuilder := anCodingAgentBuilder
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
AbOrchestrationStep >> activeCodingAgentBuilder [
	^ codingAgentBuilder ifNil: [ orchestration defaultCodingAgentBuilder ]
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
AbOrchestrationStep >> prepareTopicFrom: aBuilder using: anCodingAgentBuilder [
	| topic |
	topic := aBuilder topic.
	topic agentArguments: anCodingAgentBuilder agentArguments.
	topic workingDirectoryPath: self sharedDirectoryPath.
	topic settings aiPermissionWaitTimeoutSeconds: 0.
	topic settings aiPermissionTimeoutOption: #allow_once.
	topic settings exportApprovalWaitTimeoutSeconds: 0.
	topic settings exportApprovalTimeoutOption: #allow_once.
	AbTopicManager activeManager addTopic: topic.
	^ topic
]

{ #category : 'private' }
AbOrchestrationStep >> isCompletionFor: aTopic status: aStatus [
	^ (aTopic topicGoal description isNil or: [ aTopic topicGoal description isEmpty ])
		ifTrue: [ aStatus = #endTurn ]
		ifFalse: [ aStatus = #goalAchieved ]
]

{ #category : 'private' }
AbOrchestrationStep >> subscribeCompletionSemaphore: aSemaphore forTopic: aTopic [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann |
			(self isCompletionFor: aTopic status: ann status)
				ifTrue: [ aSemaphore signal ] ]
		for: self
]

{ #category : 'private' }
AbOrchestrationStep >> combinedResultsFrom: aCollectionOfTopics [
	| results |
	results := aCollectionOfTopics collect: [ :topic | self resultFromTopic: topic ].
	results := results reject: #isNil.
	^ results ifEmpty: [ nil ] ifNotEmpty: [ results joinUsing: String crlf , String crlf ]
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
