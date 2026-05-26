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

	AbTopicManager forTest topicsDo: [ :topic |
		| dir |
		dir := topic workingDirectory path.
		(dir basename beginsWith: 'ab-test-') ifTrue: [
			dir exists ifTrue: [ dir deleteAll ] ] ].
	AbTopicManager forTest: nil.
	self cleanupTestDirectories
]

{ #category : 'running' }
AbTestCase >> cleanupTestDirectories [

	| agenticBrowserDir |
	agenticBrowserDir := AbSettings defaultAgenticBrowserRootDirectory.
	agenticBrowserDir exists ifFalse: [ ^ self ].
	agenticBrowserDir children do: [ :each |
		(each basename beginsWith: 'ab-test-') ifTrue: [ each deleteAll ] ]
]

{ #category : 'private' }
AbTestCase >> newMockTopic [

	^ self newMockTopic: 'unnamed'
]

{ #category : 'private' }
AbTestCase >> newMockTopic: aString [

	^ AbMockTopicNoPromptSend new title: 'ab-test-' , aString
]

{ #category : 'private' }
AbTestCase >> newTopic [

	^ self newTopic: 'unnamed'
]

{ #category : 'private' }
AbTestCase >> newTopic: aString [

	^ AbTopic new title: 'ab-test-' , aString
]

{ #category : 'private' }
AbTestCase >> modelOptionWithCurrentValue: aString [

	| modelOption |
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues
		at: 'id' put: 'model';
		at: 'currentValue' put: aString;
		at: 'type' put: 'select';
		at: 'options' put: {
				(Dictionary new
					 at: 'value' put: 'claude-sonnet-4-6';
					 at: 'name' put: 'claude-sonnet-4-6';
					 yourself).
				(Dictionary new
					 at: 'value' put: 'claude-opus-4-7';
					 at: 'name' put: 'claude-opus-4-7';
					 yourself) }.
	^ modelOption
]

{ #category : 'private' }
AbTestCase >> modeOptionWithCurrentValue: aString [

	| modeOption |
	modeOption := ACPConfigOption new beModeCategory.
	modeOption rawValues
		at: 'id' put: 'mode';
		at: 'currentValue' put: aString;
		at: 'options' put: {
				(Dictionary new
					 at: 'value' put: 'ask';
					 at: 'name' put: 'Ask';
					 yourself).
				(Dictionary new
					 at: 'value' put: 'code';
					 at: 'name' put: 'Code';
					 yourself) }.
	^ modeOption
]
