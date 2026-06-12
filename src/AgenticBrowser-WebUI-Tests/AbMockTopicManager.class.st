"
I am a test double for AbTopicManager that records whether save was called, avoiding disk I/O in tests.
"
Class {
	#name : 'AbMockTopicManager',
	#superclass : 'AbTopicManager',
	#instVars : [
		'saved'
	],
	#category : 'AgenticBrowser-WebUI-Tests',
	#package : 'AgenticBrowser-WebUI-Tests'
}

{ #category : 'accessing' }
AbMockTopicManager >> save [

	saved := true
]

{ #category : 'testing' }
AbMockTopicManager >> wasSaved [

	^ saved = true
]
