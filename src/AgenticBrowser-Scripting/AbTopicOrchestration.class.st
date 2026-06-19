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
AbTopicOrchestration class >> build: aBlock [
	^ self build: aBlock using: AbTopicOrchestrationBuilder
]

{ #category : 'building' }
AbTopicOrchestration class >> build: aBlock using: aBuilderClass [
	| builder orchestration |
	builder := aBuilderClass new.
	aBlock value: builder.
	orchestration := self new
		steps: builder steps;
		yourself.
	orchestration steps do: [ :step | step orchestration: orchestration ].
	^ orchestration
]

{ #category : 'initialization' }
AbTopicOrchestration >> initialize [
	super initialize.
	steps := OrderedCollection new.
	sharedDirectoryPath := (Smalltalk imageDirectory / 'agentic-browser' / ('orchestration-' , UUID new asString36)) fullName.
]

{ #category : 'accessing' }
AbTopicOrchestration >> steps [
	^ steps
]

{ #category : 'accessing' }
AbTopicOrchestration >> steps: aCollection [
	steps := aCollection
]

{ #category : 'accessing' }
AbTopicOrchestration >> sharedDirectoryPath [
	^ sharedDirectoryPath
]

{ #category : 'accessing' }
AbTopicOrchestration >> sharedDirectoryPath: aString [
	sharedDirectoryPath := aString
]

{ #category : 'running' }
AbTopicOrchestration >> run [
	| stepResult |
	self steps do: [ :step |
		step sharedDirectoryPath: self sharedDirectoryPath.
		step previousResult: stepResult.
		stepResult := step run ].
	^ stepResult
]

