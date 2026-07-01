"
I am the abstract base class for orchestration objects.

I provide shared identity, naming, settings, logging, announcement infrastructure,
persistence (Fuel save/load), and a shared working directory — used by both
AbTopicOrchestration and AbOrchestrationGroup.

Responsibility:
- Hold a stable UUID as identity (id)
- Hold a human-readable name (name)
- Hold a settings copy (settings)
- Hold a shared working directory path (sharedDirectoryPath)
- Provide a shared logger instance (logger)
- Provide an announcer for lifecycle events (announcer)
- Manage Fuel persistence (save/load via #save, #saveTo:, #loadFrom:)

Collaborators:
- AbSettings: provides default settings and the root directory for persistence
- AbLocalLogger: default logger implementation
- AbOrchestrationEnded: announced on run completion by subclasses

Public API and Key Messages:
- #buildBy: aBlock - configure the orchestration via a DSL builder block
- #run - execute all steps in order; blocks until complete (Template Method)
- #result - returns the result string of the last completed step
- #save / #saveTo: aFileReference - persist to disk via Fuel serialization
- #loadFrom: aFileReference - class-side; deserialize a previously saved instance
- #explore - open inspector on orchestration state (id, steps, result)

Internal Representation:
- id - UUID string; lazy-initialized on first access
- name - human-readable label; defaults to 'orchestration'
- steps - OrderedCollection of step instances
- settings - AbSettings copy; defaults to AbSettings defaultCopied
- logger - AbLocalLogger; transient (excluded from Fuel serialization)
- announcer - Announcer; transient (excluded from Fuel serialization)
- sharedDirectoryPath - working directory path; lazy-initialized from settings
- previousResult - result injected from an outer context (e.g. a containing group)
"
Class {
	#name : 'AbBaseOrchestration',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'steps',
		'settings',
		'logger',
		'announcer',
		'sharedDirectoryPath',
		'previousResult'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbBaseOrchestration class >> buildBy: aBlock [
	^ self new buildBy: aBlock
]

{ #category : 'persistence' }
AbBaseOrchestration class >> loadFrom: aFileReference [
	| loaded |
	loaded := FLMaterializer materializeFromFileNamed: aFileReference fullName.
	loaded class == self ifFalse: [
		self error: 'Deserialized object is not a ' , self name ].
	^ loaded
]

{ #category : 'building' }
AbBaseOrchestration >> buildBy: aBlock [
	| builder |
	builder := self orchestrationBuilderClass on: self.
	aBlock value: builder.
]

{ #category : 'building' }
AbBaseOrchestration >> orchestrationBuilderClass [
	^ self subclassResponsibility
]

{ #category : 'initialization' }
AbBaseOrchestration >> initialize [
	super initialize.
	steps := OrderedCollection new.
]

{ #category : 'accessing' }
AbBaseOrchestration >> steps [
	^ steps
]

{ #category : 'accessing' }
AbBaseOrchestration >> steps: aCollection [
	steps := aCollection
]

{ #category : 'fuel' }
AbBaseOrchestration class >> fuelIgnoredInstanceVariableNames [
	^ #( 'logger' 'announcer' )
]

{ #category : 'accessing' }
AbBaseOrchestration >> basicSharedDirectoryPath [
	^ sharedDirectoryPath
]

{ #category : 'accessing' }
AbBaseOrchestration >> defaultSharedDirectoryPath [
	^ (AbSettings defaultAgenticBrowserRootDirectory / self directoryName) fullName
]

{ #category : 'accessing' }
AbBaseOrchestration >> directoryName [
	^ self shortReferenceName
]

{ #category : 'inspecting' }
AbBaseOrchestration >> explore [
	{ #orchestration -> self. #steps -> self steps. #result -> self result } asDictionary inspect
]

{ #category : 'accessing' }
AbBaseOrchestration >> safeName [
	| safe |
	safe := self name collect: [ :c |
		(c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			ifTrue: [ c ]
			ifFalse: [ $- ] ].
	safe ifEmpty: [ safe := 'orchestration' ].
	^ safe
]

{ #category : 'accessing' }
AbBaseOrchestration >> previousResult [
	^ previousResult
]

{ #category : 'accessing' }
AbBaseOrchestration >> previousResult: aString [
	previousResult := aString
]

{ #category : 'accessing' }
AbBaseOrchestration >> result [
	^ (steps select: [ :each | each stepResult notNil ])
		ifNotEmpty: [ :completed | completed last stepResult ]
]

{ #category : 'persistence' }
AbBaseOrchestration >> save [
	self saveTo: self sharedDirectoryPath asFileReference / (self shortReferenceName , '.fuel')
]

{ #category : 'persistence' }
AbBaseOrchestration >> saveTo: aFileReference [
	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: self toFileNamed: aFileReference fullName
]

{ #category : 'accessing' }
AbBaseOrchestration >> sharedDirectoryPath [
	^ sharedDirectoryPath ifNil: [
		sharedDirectoryPath := self defaultSharedDirectoryPath ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> sharedDirectoryPath: aString [
	sharedDirectoryPath := aString
]

{ #category : 'accessing' }
AbBaseOrchestration >> shortReferenceName [
	^ self safeName , '-' , (self id copyFrom: 1 to: 8)
]

{ #category : 'accessing' }
AbBaseOrchestration >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> id [
	^ id ifNil: [ id := UUID new asString36 ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> name [
	^ name ifNil: [ name := 'orchestration' ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> name: aString [
	name := aString
]

{ #category : 'accessing' }
AbBaseOrchestration >> settings [
	^ settings ifNil: [ settings := AbSettings defaultCopied ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> settings: anAbSettings [
	settings := anAbSettings
]

{ #category : 'running' }
AbBaseOrchestration >> run [
	| stepResult |
	self logger debug: self runLogLabel , ' run: start name=' , self name , ' steps=' , self steps size printString.
	stepResult := self previousResult.
	[
		self prepareRun.
		self steps do: [ :step |
			step previousStepResult: stepResult.
			stepResult := step run.
			step stepResult: stepResult ]
	] ensure: [
		self afterRun.
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	self logger debug: self runLogLabel , ' run: end name=' , self name.
	^ stepResult
]

{ #category : 'running' }
AbBaseOrchestration >> resume [
	| stepResult |
	self logger debug: self runLogLabel , ' resume: start name=' , self name , ' steps=' , self steps size printString.
	stepResult := self previousResult.
	[
		self prepareRun.
		self steps do: [ :step |
			step stepResult isNil
				ifTrue: [
					step previousStepResult: stepResult.
					stepResult := step run.
					step stepResult: stepResult ]
				ifFalse: [ stepResult := step stepResult ] ]
	] ensure: [
		self afterRun.
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	self logger debug: self runLogLabel , ' resume: end name=' , self name.
	^ stepResult
]

{ #category : 'running' }
AbBaseOrchestration >> runLogLabel [
	^ 'Orchestration'
]

{ #category : 'running' }
AbBaseOrchestration >> prepareRun [
	"hook: subclasses may override to perform pre-loop setup"
]

{ #category : 'running' }
AbBaseOrchestration >> afterRun [
	"hook: subclasses may override to perform post-loop cleanup before announcement"
]
