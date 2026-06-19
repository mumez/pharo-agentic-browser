Class {
	#name : 'AbSequentialStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbSequentialStep >> run [
	| currentResult |
	currentResult := self previousResult.
	self topicBuilders do: [ :builder |
		| topic semaphore activeCodingAgentBuilder |
		activeCodingAgentBuilder := self activeCodingAgentBuilder.
		topic := builder prepareWith: activeCodingAgentBuilder for: self.
		topic registerTo: self orchestration topicManager.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		topic session ensureConnected.
		activeCodingAgentBuilder onConnected: topic.
		topic sendPrompt: (self promptForBuilder: builder topic: topic injecting: currentResult).
		semaphore wait.
		currentResult := self resultFromTopic: topic ].
	^ currentResult
]
