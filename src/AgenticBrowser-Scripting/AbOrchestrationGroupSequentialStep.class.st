"
I run my items one after another and return the last item's result.

I chain results between items: if the previous item produced a non-nil result, I pass it to
the next via #previousResult: before calling #run. This mirrors the result-chaining done by
AbOrchestrationSequentialStep at the topic level.
"
Class {
	#name : 'AbOrchestrationGroupSequentialStep',
	#superclass : 'AbOrchestrationGroupStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupSequentialStep >> basicRun [
	| result |
	result := self previousStepResult.
	self items do: [ :item |
		result ifNotNil: [ item previousResult: result ].
		result := item run ].
	self stepResult: result.
	^ result
]
