"
I am the abstract base class for a single step in an AbTopicOrchestration.

A step owns a collection of AbTopicBuilder instances and one AbCodingAgentBuilder. Concrete subclasses
(AbSequentialStep, AbParallelStep) implement #run and decide whether topics execute one at a time or
concurrently.

I handle the common concerns: preparing topics, subscribing to completion events, waiting with timeout,
extracting results, and injecting the previous step's result into each topic's initial prompt.

Responsibility:
- Prepare and register topics with AbTopicManager
- Subscribe to AbTopicStatusChanged to detect completion (#endTurn or #goalAchieved)
- Wait for each topic to complete; raise AbOrchestrationStepTimeout on timeout
- Extract results from completed topics (goal result file or last AI message)
- Inject the previous step's result into topic prompts under a delimiter header
- Combine parallel results into a single string for the next step

Collaborators:
- AbTopicOrchestration: provides logger, settings, topicManager, and sharedDirectoryPath
- AbTopicBuilder: builds and configures each topic
- AbCodingAgentBuilder: configures agent arguments and mode on each topic
- AbOrchestrationStepTimeout: raised when a topic exceeds the step wait timeout
- AbTopic: the domain object being run and observed

Internal Representation:
- orchestration - parent AbTopicOrchestration
- topicBuilders - collection of AbTopicBuilder
- codingAgentBuilder - AbCodingAgentBuilder for this step
- sharedDirectoryPath - working directory (set by orchestration before run)
- previousStepResult - result string injected from the prior step
- stepResult - result string produced by this step
"
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
AbOrchestrationStep >> logger [
	^ self orchestration logger
]

{ #category : 'accessing' }
AbOrchestrationStep >> settings [
	^ self orchestration settings
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
AbOrchestrationStep >> topics [
	^ self topicBuilders collect: [ :each | each topic ]
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

{ #category : 'error handling' }
AbOrchestrationStep >> waitWithTimeoutOn: aSemaphore [
	(aSemaphore waitTimeoutSeconds: self settings orchestrationStepWaitTimeoutSeconds)
		ifTrue: [ (AbOrchestrationStepTimeout step: self) signal ]
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
	| titleResultPairs |
	titleResultPairs := (aCollectionOfTopics
		collect: [ :topic | { topic title. self resultFromTopic: topic } ])
		select: [ :pair | pair last notNil ].
	^ String streamContents: [ :strm |
		titleResultPairs
			do: [ :pair |
				strm << '=== ' << pair first << ' ==='; crlf.
				strm << pair second ]
			separatedBy: [ strm crlf; crlf ] ]
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
