"
I execute my topics one after another, passing each topic's result to the next.

I am a concrete AbOrchestrationStep. For each topic I wait until it completes (#endTurn or
#goalAchieved), extract the result, and inject it into the following topic's prompt via the
'=== Previous Topic Result ===' header.
"
Class {
	#name : 'AbSequentialStep',
	#superclass : 'AbOrchestrationStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}


{ #category : 'running' }
AbSequentialStep >> run [
	| currentResult topics |
	self logger debug: 'SequentialStep run: start topics=' , self topicBuilders size printString.
	currentResult := self previousStepResult.
	topics := self prepareTopicsForRun.
	self topicBuilders with: topics do: [ :builder :topic |
		| semaphore |
		self logger debug: 'SequentialStep run: topic start title=' , topic title.
		semaphore := Semaphore new.
		self subscribeCompletionSemaphore: semaphore forTopic: topic.
		self runTopic: topic topicBuilder: builder agentBuilder: self activeCodingAgentBuilder resultInjecting: currentResult.
		self waitWithTimeoutOn: semaphore.
		currentResult := self resultFromTopic: topic.
		self logger debug: 'SequentialStep run: topic end title=' , topic title ].
	self logger debug: 'SequentialStep run: end'.
	^ currentResult
]
