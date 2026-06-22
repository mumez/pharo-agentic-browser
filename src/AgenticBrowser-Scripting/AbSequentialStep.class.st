Class {
	#name : 'AbSequentialStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}


{ #category : 'running' }
AbSequentialStep >> run [
	| currentResult topics |
	currentResult := self previousStepResult.
	topics := self prepareTopicsForRun.
	self topicBuilders with: topics do: [ :builder :topic |
		| semaphore |
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		self runTopic: topic topicBuilder: builder agentBuilder: self activeCodingAgentBuilder resultInjecting: currentResult.
		self waitWithTimeoutOn: semaphore.
		currentResult := self resultFromTopic: topic ].
	^ currentResult
]
