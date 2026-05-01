Class {
	#name : 'AbTestCase',
	#superclass : 'TestCase',
	#instVars : [],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTestCase >> setUp [

	AbTopicManager forTest: AbTopicManager new
]

{ #category : 'running' }
AbTestCase >> tearDown [

	AbTopicManager forTest: nil
]
