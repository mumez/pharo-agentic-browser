"
I am a test double for AbTopicManager that records whether save was called, avoiding disk I/O in tests.
"
Class {
	#name : 'AbMockTopicManager',
	#superclass : 'AbTopicManager',
	#instVars : [
		'saved',
		'shouldFail'
	],
	#category : 'AgenticBrowser-WebUI-Tests',
	#package : 'AgenticBrowser-WebUI-Tests'
}

{ #category : 'accessing' }
AbMockTopicManager >> makeSaveFail [

	shouldFail := true
]

{ #category : 'accessing' }
AbMockTopicManager >> save [

	shouldFail = true ifTrue: [ Error signal: 'Save failed for test' ].
	saved := true
]

{ #category : 'testing' }
AbMockTopicManager >> wasSaved [

	^ saved = true
]
