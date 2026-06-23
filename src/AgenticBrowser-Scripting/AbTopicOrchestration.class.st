Class {
	#name : 'AbTopicOrchestration',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'steps',
		'sharedDirectoryPath',
		'settings'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbTopicOrchestration class >> buildBy: aBlock [
	^ self new buildBy: aBlock
]


{ #category : 'building' }
AbTopicOrchestration >> buildBy: aBlock [
	| builder |
	builder := self orchestrationBuilderClass new.
	aBlock value: builder.
	self steps: builder steps.
	self steps do: [ :step | step orchestration: self ]
]

{ #category : 'building' }
AbTopicOrchestration >> orchestrationBuilderClass [
	^ AbTopicOrchestrationBuilder
]

{ #category : 'initialization' }
AbTopicOrchestration >> initialize [
	super initialize.
	steps := OrderedCollection new.
]

{ #category : 'running' }
AbTopicOrchestration >> run [
	| stepResult |
	stepResult := nil.
	self steps do: [ :step |
		step sharedDirectoryPath: self sharedDirectoryPath.
		step previousStepResult: stepResult.
		stepResult := step run.
		step stepResult: stepResult ].
	^ stepResult
]

{ #category : 'accessing' }
AbTopicOrchestration >> result [
	^ (steps select: [ :each | each stepResult notNil ])
		ifNotEmpty: [ :completed | completed last stepResult ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> topicManager [
	^ AbTopicManager default
]

{ #category : 'accessing' }
AbTopicOrchestration >> safeName [

	| safe |
	safe := self name collect: [ :c |
		    (c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			    ifTrue: [ c ]
			    ifFalse: [ $- ] ].
	safe ifEmpty: [ safe := 'orchestration' ].
	^ safe
]

{ #category : 'defaults' }
AbTopicOrchestration >> directoryName [
	^ self safeName , '-' , (self id copyFrom: 1 to: 8)
]

{ #category : 'defaults' }
AbTopicOrchestration >> defaultSharedDirectoryPath [
	^ (AbSettings defaultAgenticBrowserRootDirectory / self directoryName) fullName
]

{ #category : 'accessing' }
AbTopicOrchestration >> sharedDirectoryPath [
	^ sharedDirectoryPath ifNil: [
		sharedDirectoryPath := self defaultSharedDirectoryPath ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> sharedDirectoryPath: aString [
	sharedDirectoryPath := aString
]

{ #category : 'accessing' }
AbTopicOrchestration >> settings [
	^ settings ifNil: [ settings := AbSettings defaultCopied ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> settings: anAbSettings [
	settings := anAbSettings
]

{ #category : 'accessing' }
AbTopicOrchestration >> id [
	^ id ifNil: [ id := UUID new asString36 ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> name [
	^ name ifNil: [ name := 'orchestration' ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> name: aString [
	name := aString
]

{ #category : 'accessing' }
AbTopicOrchestration >> steps [
	^ steps
]

{ #category : 'accessing' }
AbTopicOrchestration >> steps: aCollection [
	steps := aCollection
]
