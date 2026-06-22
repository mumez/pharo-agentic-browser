Class {
	#name : 'AbTopicOrchestration',
	#superclass : 'Object',
	#instVars : [
		'steps',
		'sharedDirectoryPath'
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

{ #category : 'defaults' }
AbTopicOrchestration >> defaultDirectoryNamePrefix [
	^ 'orchestration-'
]

{ #category : 'defaults' }
AbTopicOrchestration >> defaultSharedDirectoryPath [
	^ (AbSettings defaultAgenticBrowserRootDirectory / (self defaultDirectoryNamePrefix , UUID new asString36)) fullName
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
AbTopicOrchestration >> steps [
	^ steps
]

{ #category : 'accessing' }
AbTopicOrchestration >> steps: aCollection [
	steps := aCollection
]
