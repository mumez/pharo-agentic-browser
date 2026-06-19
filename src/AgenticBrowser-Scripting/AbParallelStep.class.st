Class {
	#name : 'AbParallelStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbParallelStep >> run [
	| topics semaphores incomingResult |
	incomingResult := self previousResult.
	topics := self prepareTopicsForRun.
	semaphores := self topicBuilders with: topics collect: [ :builder :topic |
		| semaphore |
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		[ self runTopic: topic topicBuilder: builder agentBuilder: self copiedCodingAgentBuilder resultInjecting: incomingResult ] fork.
		semaphore ].
	semaphores do: [ :sem | sem wait ].
	^ self combinedResultsFrom: topics
]
