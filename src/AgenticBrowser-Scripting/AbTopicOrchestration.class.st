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
AbTopicOrchestration class >> orchestrationBuilderClass [
	^ AbTopicOrchestrationBuilder
]

{ #category : 'building' }
AbTopicOrchestration >> buildBy: aBlock [
	| builder |
	builder := self class orchestrationBuilderClass new.
	aBlock value: builder.
	steps := builder steps.
	steps do: [ :step | step orchestration: self ].
	^ self
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

