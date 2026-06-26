"
I run my items concurrently by forking each one, waiting for all to complete via AbOrchestrationEnded.
"
Class {
	#name : 'AbOrchestrationGroupParaNode',
	#superclass : 'AbOrchestrationGroupNode',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupParaNode >> run [
	| semaphore |
	semaphore := Semaphore new.
	self items do: [ :item |
		item announcer
			when: AbOrchestrationEnded
			do: [ semaphore signal ]
			for: self.
		[ item run ] fork ].
	self items size timesRepeat: [ semaphore wait ].
	self items do: [ :item | item announcer unsubscribe: self ]
]
