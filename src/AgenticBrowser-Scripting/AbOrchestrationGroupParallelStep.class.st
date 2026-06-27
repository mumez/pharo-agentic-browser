"
I run my items concurrently by forking each one, waiting for all to complete via AbOrchestrationEnded.
"
Class {
	#name : 'AbOrchestrationGroupParallelStep',
	#superclass : 'AbOrchestrationGroupStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupParallelStep >> run [
	| semaphore |
	semaphore := Semaphore new.
	self items do: [ :item |
		item announcer
			when: AbOrchestrationEnded
			do: [ semaphore signal ]
			for: self.
		[ item run ] fork ].
	self items size timesRepeat: [ self waitWithTimeoutOn: semaphore ].
	self items do: [ :item | item announcer unsubscribe: self ]
]

{ #category : 'private' }
AbOrchestrationGroupParallelStep >> waitWithTimeoutOn: aSemaphore [
	(aSemaphore waitTimeoutSeconds: self settings orchestrationGroupItemWaitTimeoutSeconds)
		ifTrue: [ (AbOrchestrationStepTimeout step: self) signal ]
]
