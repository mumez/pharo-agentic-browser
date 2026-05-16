Class {
	#name : 'AbTestCase',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTestCase >> setUp [

	AbTopicManager forTest: AbTopicManager new
]

{ #category : 'running' }
AbTestCase >> tearDown [

	AbTopicManager default topicsDo: [ :topic |
		| dir |
		dir := topic workingDirectory path.
		dir exists ifTrue: [ dir deleteAll ] ].
	AbTopicManager forTest: nil
]
