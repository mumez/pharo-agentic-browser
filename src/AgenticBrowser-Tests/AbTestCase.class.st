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
