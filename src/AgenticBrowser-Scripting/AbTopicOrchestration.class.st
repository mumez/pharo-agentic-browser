"
I represent a multi-topic orchestration that coordinates AI agent sessions in a structured workflow.

I am the root object of the Scripting DSL. I hold an ordered collection of steps (sequential or
parallel) and run them in order when #run is called. Steps share a common working directory under
the AgenticBrowser root.

Responsibility:
- Hold and execute an ordered list of AbOrchestrationStep instances
- Provide a shared working directory for all steps
- Propagate results between steps
- Manage Fuel persistence (save/load)
- Clean up topics from AbTopicManager after the run (unless lingerOrchestrationTopicsAfterRun is true)

Collaborators:
- AbTopicOrchestrationBuilder: builds my steps from a DSL block
- AbOrchestrationStep (subclasses): executed in sequence; each returns a result string
- AbSettings: provides default settings (timeouts, linger behavior)
- AbTopicManager: topics are registered to and optionally removed from it
- AgenticBrowser: class-side entry points #scriptBy: and #runBy: create me

Public API and Key Messages:
- #buildBy: aBlock - configure steps via DSL builder block
- #run - execute all steps in order; blocks until complete; returns final result
- #result - returns the result of the last completed step
- #save / #saveTo: - persist to disk via Fuel serialization
- #explore - open inspector on orchestration state

Internal Representation:
- id - stable UUID used as part of the shared directory name
- name - human-readable name (defaults to 'orchestration')
- steps - OrderedCollection of AbOrchestrationStep
- sharedDirectoryPath - common working directory for all topics
- settings - AbSettings copy (controls timeouts and linger behavior)
- logger - for debug output
"
Class {
	#name : 'AbTopicOrchestration',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'steps',
		'sharedDirectoryPath',
		'settings',
		'logger',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbTopicOrchestration class >> buildBy: aBlock [
	^ self new buildBy: aBlock
]

{ #category : 'fuel' }
AbTopicOrchestration class >> fuelIgnoredInstanceVariableNames [
	^ #( 'logger' 'announcer' )
]

{ #category : 'persistence' }
AbTopicOrchestration class >> loadFrom: aFileReference [

	| loaded |
	loaded := FLMaterializer materializeFromFileNamed: aFileReference fullName.
	loaded class == self ifFalse: [
		self error: 'Deserialized object is not a ' , self name ].
	^ loaded
]


{ #category : 'building' }
AbTopicOrchestration >> buildBy: aBlock [
	| builder |
	builder := self orchestrationBuilderClass on: self.
	aBlock value: builder.
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
	self logger debug: 'Orchestration run: start name=' , self name , ' steps=' , self steps size printString.
	stepResult := nil.
	[
		self steps do: [ :step |
			step previousStepResult: stepResult.
			stepResult := step run.
			step stepResult: stepResult ]
	] ensure: [
		self settings lingerOrchestrationTopicsAfterRun ifFalse: [ self removeTopicsFromManager ].
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	self logger debug: 'Orchestration run: end name=' , self name.
	^ stepResult
]

{ #category : 'persistence' }
AbTopicOrchestration >> save [
	self saveTo: self sharedDirectoryPath asFileReference / (self shortReferenceName , '.fuel')
]

{ #category : 'persistence' }
AbTopicOrchestration >> saveTo: aFileReference [
	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: self toFileNamed: aFileReference fullName
]

{ #category : 'running' }
AbTopicOrchestration >> removeTopicsFromManager [
	self steps do: [ :step |
		step topics do: [ :topic | self topicManager removeTopic: topic ] ]
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

{ #category : 'accessing' }
AbTopicOrchestration >> shortReferenceName [
	^ self safeName , '-' , (self id copyFrom: 1 to: 8)
]

{ #category : 'defaults' }
AbTopicOrchestration >> directoryName [
	^ self shortReferenceName
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

{ #category : 'accessing' }
AbTopicOrchestration >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbTopicOrchestration >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'inspecting' }
AbTopicOrchestration >> explore [
	{ #orchestration -> self. #steps -> self steps. #result -> self result }
		asDictionary inspect
]
