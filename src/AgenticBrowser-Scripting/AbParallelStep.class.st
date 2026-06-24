"
I execute all my topics concurrently, then wait for all to finish before returning.

I am a concrete AbOrchestrationStep. I fork each topic run, wait on individual semaphores, then
combine all results into a single string that is injected into the first topic of the next step.
"
Class {
	#name : 'AbParallelStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbParallelStep >> run [
	| topics semaphores incomingResult |
	self logger debug: 'ParallelStep run: start topics=' , self topicBuilders size printString.
	incomingResult := self previousStepResult.
	topics := self prepareTopicsForRun.
	semaphores := self topicBuilders with: topics collect: [ :builder :topic |
		| semaphore |
		self logger debug: 'ParallelStep run: topic start title=' , topic title.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		[ self runTopic: topic topicBuilder: builder agentBuilder: self copiedCodingAgentBuilder resultInjecting: incomingResult ] fork.
		semaphore ].
	semaphores do: [ :sem | self waitWithTimeoutOn: sem ].
	self logger debug: 'ParallelStep run: end'.
	^ self combinedResultsFrom: topics
]
