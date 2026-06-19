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
		| topic semaphore activeConfig |
		activeConfig := self activeAgentConfig.
		topic := self prepareTopicFrom: builder using: activeConfig.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		topic session ensureConnected.
		activeConfig onConnected: topic.
		topic sendPrompt: (self promptForBuilder: builder topic: topic injecting: currentResult).
		semaphore wait.
		currentResult := self resultFromTopic: topic ].
	^ currentResult
]
