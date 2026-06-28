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
		'sharedDirectoryPath'
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
	{ #orchestration -> self. #steps -> self steps } asDictionary inspect
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
