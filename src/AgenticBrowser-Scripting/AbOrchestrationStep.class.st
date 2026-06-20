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
	^ codingAgentBuilder ifNil: [ self error: 'codingAgentBuilder is not set' ]
]

{ #category : 'factory' }
AbOrchestrationStep >> copiedCodingAgentBuilder [
	^ self activeCodingAgentBuilder copyForRun
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
AbOrchestrationStep >> runTopic: aTopic topicBuilder: aBuilder agentBuilder: anAgentBuilder resultInjecting: aResult [
	aTopic session ensureConnected.
	anAgentBuilder onConnected: aTopic.
	aBuilder onConnected: aTopic.
	self waitForPostConnectPromptIfNeededFor: aTopic.
	aTopic isGoalAchieved ifTrue: [ ^ self ].
	aTopic sendPrompt: (self promptForBuilder: aBuilder topic: aTopic injecting: aResult)
]

{ #category : 'private' }
AbOrchestrationStep >> waitForPostConnectPromptIfNeededFor: aTopic [
	| completionSignal subscriptionOwner |
	(aTopic isWorking or: [ aTopic isWaitingForHuman ]) ifFalse: [ ^ self ].
	completionSignal := Semaphore new.
	subscriptionOwner := Object new.
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :ann |
			(ann status = #endTurn or: [ ann status = #goalAchieved ]) ifTrue: [
				completionSignal signal ] ]
		for: subscriptionOwner.
	(aTopic isWorking or: [ aTopic isWaitingForHuman ]) ifFalse: [
		aTopic announcer unsubscribe: subscriptionOwner.
		^ self ].
	[
		completionSignal wait
	] ensure: [ aTopic announcer unsubscribe: subscriptionOwner ]
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
