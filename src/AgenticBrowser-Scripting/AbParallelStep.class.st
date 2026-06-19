Class {
	#name : 'AbParallelStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbParallelStep >> run [
	| semaphores topics incomingResult |
	incomingResult := self previousResult.
	topics := OrderedCollection new.
	semaphores := self topicBuilders collect: [ :builder |
		| topic semaphore activeCodingAgentBuilder |
		activeCodingAgentBuilder := self activeCodingAgentBuilder.
		topic := builder prepareWith: activeCodingAgentBuilder for: self.
		topic registerTo: self orchestration topicManager.
		topics add: topic.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		[
			topic session ensureConnected.
			activeCodingAgentBuilder onConnected: topic.
			topic sendPrompt: (self promptForBuilder: builder topic: topic injecting: incomingResult)
		] fork.
		semaphore ].
	semaphores do: [ :sem | sem wait ].
	^ self combinedResultsFrom: topics
]
