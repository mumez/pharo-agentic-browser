Extension { #name : 'AbTopicManager' }

{ #category : '*AgenticBrowser-Scripting' }
AbTopicManager class >> activeManager [
	^ forTest ifNil: [ self default ]
]
