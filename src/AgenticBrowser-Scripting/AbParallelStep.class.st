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
		| topic semaphore activeConfig |
		activeConfig := self activeAgentConfig.
		topic := self prepareTopicFrom: builder using: activeConfig.
		topics add: topic.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		[
			topic session ensureConnected.
			activeConfig onConnected: topic.
			topic sendPrompt: (self promptForBuilder: builder topic: topic injecting: incomingResult)
		] fork.
		semaphore ].
	semaphores do: [ :sem | sem wait ].
	^ self combinedResultsFrom: topics
]
