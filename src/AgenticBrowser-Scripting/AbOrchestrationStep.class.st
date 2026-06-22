Class {
	#name : 'AbOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'topicBuilders',
		'codingAgentBuilder',
		'sharedDirectoryPath',
		'previousStepResult',
		'stepResult'
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
	^ codingAgentBuilder ifNil: [ self error: 'codingAgentBuilder is not set' ]
]

{ #category : 'factory' }
AbOrchestrationStep >> copiedCodingAgentBuilder [
	^ self activeCodingAgentBuilder copyForRun
]

{ #category : 'accessing' }
AbOrchestrationStep >> previousStepResult [
	^ previousStepResult
]

{ #category : 'accessing' }
AbOrchestrationStep >> previousStepResult: aString [
	previousStepResult := aString
]

{ #category : 'accessing' }
AbOrchestrationStep >> stepResult [
	^ stepResult
]

{ #category : 'accessing' }
AbOrchestrationStep >> stepResult: aString [
	stepResult := aString
]

{ #category : 'running' }
AbOrchestrationStep >> prepareTopicsForRun [
	| agentBuilder |
	agentBuilder := self activeCodingAgentBuilder.
	^ self topicBuilders collect: [ :builder |
		| topic |
		topic := builder prepareWith: agentBuilder for: self.
		topic registerTo: self orchestration topicManager.
		topic ]
]

{ #category : 'running' }
AbOrchestrationStep >> run [
	self subclassResponsibility
]

{ #category : 'private' }
AbOrchestrationStep >> runTopic: aTopic topicBuilder: aTopicBuilder agentBuilder: anAgentBuilder resultInjecting: aResult [
	aTopic session ensureConnected.
	anAgentBuilder finalizeOnSessionEstablished: aTopic.
	aTopicBuilder finalizeOnSessionEstablished: aTopic.
	aTopic sendPrompt: (self promptForBuilder: aTopicBuilder topic: aTopic injecting: aResult)
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
	| topicResults |
	topicResults := aCollectionOfTopics collect: [ :topic | self resultFromTopic: topic ].
	topicResults := topicResults reject: #isNil.
	^ topicResults ifEmpty: [ nil ] ifNotEmpty: [ topicResults joinUsing: String crlf , String crlf ]
]

{ #category : 'private' }
AbOrchestrationStep >> promptForBuilder: aBuilder topic: aTopic injecting: aPreviousResult [
	| prompt |
	prompt := aBuilder prompt ifNil: [ aTopic title ].
	aPreviousResult ifNotNil: [
		prompt := String streamContents: [ :strm |
			strm << prompt.
			strm crlf; crlf.
			strm << '=== Previous Topic Result ==='; crlf.
			strm << aPreviousResult ] ].
	aBuilder goal ifNotNil: [ :goal |
		aTopic topicGoal description: goal.
		prompt := String streamContents: [ :strm |
			strm << prompt.
			strm crlf; crlf.
			strm << aTopic topicGoal notificationPrompt ] ].
	^ prompt
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
