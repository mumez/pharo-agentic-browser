"
I run my items concurrently by forking each one, wait for all to complete via AbOrchestrationEnded,
then combine their results into a single string.

Execution detail: I subscribe to AbOrchestrationEnded on each item's announcer before forking.
A shared Semaphore is signalled once per item completion, and I wait once per item. If any wait
exceeds orchestrationGroupItemWaitTimeoutSeconds, AbOrchestrationStepTimeout is signalled.

Combined results are formatted as '=== item name ===\nresult\n\n...' blocks, mirroring the
format produced by AbOrchestrationParallelStep for topic-level parallel runs.
"
Class {
	#name : 'AbOrchestrationGroupParallelStep',
	#superclass : 'AbOrchestrationGroupStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'private' }
AbOrchestrationGroupParallelStep >> combinedResultsFromItems [
	| pairs |
	pairs := (self items
		collect: [ :item | { item name. item result } ])
		select: [ :pair | pair last notNil ].
	pairs ifEmpty: [ ^ nil ].
	^ String streamContents: [ :strm |
		pairs
			do: [ :pair |
				strm << '=== ' << pair first << ' ==='; crlf.
				strm << pair second ]
			separatedBy: [ strm crlf; crlf ] ]
]

{ #category : 'running' }
AbOrchestrationGroupParallelStep >> run [
	| semaphore result |
	semaphore := Semaphore new.
	self items do: [ :item |
		self previousStepResult ifNotNil: [ :prev | item previousResult: prev ].
		item announcer
			when: AbOrchestrationEnded
			do: [ semaphore signal ]
			for: self.
		[ item run ] fork ].
	self items size timesRepeat: [ self waitWithTimeoutOn: semaphore ].
	self items do: [ :item | item announcer unsubscribe: self ].
	result := self combinedResultsFromItems.
	self stepResult: result.
	^ result
]

{ #category : 'private' }
AbOrchestrationGroupParallelStep >> waitWithTimeoutOn: aSemaphore [
	(aSemaphore waitTimeoutSeconds: self settings orchestrationGroupItemWaitTimeoutSeconds)
		ifTrue: [ self handleTimeout: (AbOrchestrationStepTimeout step: self) ]
]
