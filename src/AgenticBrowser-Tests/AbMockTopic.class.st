Class {
	#name : 'AbMockTopic',
	#superclass : 'AbTopic',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'initialize-release' }
AbMockTopic >> initialize [

	super initialize.
	self session client: MockObject new
]
