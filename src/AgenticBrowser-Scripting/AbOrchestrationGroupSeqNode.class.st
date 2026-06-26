"
I run my items one after another and return the last item's result.
"
Class {
	#name : 'AbOrchestrationGroupSeqNode',
	#superclass : 'AbOrchestrationGroupNode',
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'running' }
AbOrchestrationGroupSeqNode >> run [
	| result |
	result := nil.
	self items do: [ :item | result := item run ].
	^ result
]
