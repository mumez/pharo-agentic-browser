"
I run my items one after another and return the last item's result.
"
Class {
	#name : 'AbOrchestrationGroupSequentialStep',
	#superclass : 'AbOrchestrationGroupStep',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupSequentialStep >> run [
	| result |
	result := nil.
	self items do: [ :item |
		result ifNotNil: [ item previousResult: result ].
		result := item run ].
	self stepResult: result.
	^ result
]
