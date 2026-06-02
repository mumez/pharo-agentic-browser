"
I manage the filesystem working directory used by an AI agent topic.

Responsibility:
- I provide and ensure the existence of the per-topic directory under <imageDir>/agentic-browser/.
- I resolve the Tonel source subdirectory by reading the .project metafile (defaults to 'src/').
- I export Pharo classes and packages to Tonel .st files in the source subdirectory.
- I track whether a package import from source is in progress via a nesting counter, suppressing re-export loops.
- I subscribe to SisServer import lifecycle events to maintain the nesting counter.

Collaborators:
- AbTopic: I am owned by a topic; I read its workingDirectoryPath for all file operations.
- AbTopicRelatedPackagesWatcher: It calls #exportClassNamed:in: and reads #isImportingFromSource.
- SisServer (PharoSmalltalkInteropServer): I subscribe to its request announcements to detect import start/end.
- TonelWriter: I use it to write class and package .st files.

Public API and Key Messages:
- #path - The FileReference for the topic's working directory root.
- #sourcePath - path / srcDirectory (e.g. .../MyTopic-abc123/src).
- #ensureExists - Create the directory if it does not exist.
- #exportClassNamed:in: - Write one class to its Tonel .class.st file.
- #exportPackageNamed: - Write an entire package snapshot to the source path.
- #isImportingFromSource - True while a Tonel import through SisServer is in progress.

Internal Representation:
- importNestingCount - Integer; incremented on import start and decremented on end to support nested imports.
- srcDirectory - Cached source subdirectory name; resolved once from the .project metafile then cached.
"
Class {
	#name : 'AbWorkingDirectory',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'importNestingCount',
		'srcDirectory'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbWorkingDirectory class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'private' }
AbWorkingDirectory >> beginImportFromSource [

	self importNestingCount: self importNestingCount + 1
]

{ #category : 'private' }
AbWorkingDirectory >> detectSrcDirectoryFromProjectMetafile [

	| projectFile projectDefinition configuredSrcDirectory defaultSrcDirectory |
	defaultSrcDirectory := 'src'.
	projectFile := self path / '.project'.
	projectFile exists ifFalse: [ ^ defaultSrcDirectory ].
	projectDefinition := [ STON fromString: projectFile contents ]
		                     on: Error
		                     do: [ ^ defaultSrcDirectory ].
	configuredSrcDirectory := projectDefinition
		at: 'srcDirectory'
		ifAbsent: [
			projectDefinition at: #srcDirectory ifAbsent: [ ^ defaultSrcDirectory ] ].
	self srcDirectory: ((configuredSrcDirectory isString and: [ configuredSrcDirectory isNotEmpty ])
		ifTrue: [ configuredSrcDirectory ]
		ifFalse: [ defaultSrcDirectory ]).
	^ self srcDirectory
]

{ #category : 'accessing' }
AbWorkingDirectory >> defaultPath [

	^ (Smalltalk imageDirectory / 'agentic-browser' / self directoryName) fullName
]

{ #category : 'accessing' }
AbWorkingDirectory >> directoryName [

	^ self safeTopicName , '-' , (topic topicId copyFrom: 1 to: 8)
]

{ #category : 'private' }
AbWorkingDirectory >> endImportFromSource [

	self importNestingCount: ((self importNestingCount - 1) max: 0)
]

{ #category : 'operations' }
AbWorkingDirectory >> ensureExists [

	self path ensureCreateDirectory
]

{ #category : 'exporting' }
AbWorkingDirectory >> exportClassNamed: aClassName in: aPackageName [

	| cls classFile |
	self ensureExists.
	cls := Smalltalk globals at: aClassName asSymbol.
	classFile := self sourcePath / aPackageName / (aClassName , '.class.st').
	classFile parent ensureCreateDirectory.
	classFile writeStreamDo: [ :stream | TonelWriter exportClass: cls on: stream ]
]

{ #category : 'exporting' }
AbWorkingDirectory >> exportPackageNamed: aPackageName [

	| snapshot writer |
	self ensureExists.
	snapshot := (MCPackage named: aPackageName) snapshot.
	writer := TonelWriter on: self sourcePath ensureCreateDirectory.
	writer writeSnapshot: snapshot
]

{ #category : 'private' }
AbWorkingDirectory >> handleSisRequestAnnouncement: requestAnnouncement [

	| urlPath importPath packageName matchingPathParts wholePathParts |
	urlPath := requestAnnouncement teapotRequest url pathPrintString.
	urlPath = '/import-package' ifFalse: [ ^ self ].
	importPath := requestAnnouncement teapotRequest at: #path ifAbsent: [ ^ self ].
	packageName := requestAnnouncement teapotRequest at: #package_name ifAbsent: [ ^ self ].
	packageName isEmptyOrNil ifTrue: [ ^ self ].
	matchingPathParts := {self srcDirectory. packageName}.
	wholePathParts := (importPath findTokens: '/\'), {packageName}.
	(wholePathParts endsWith: matchingPathParts) ifFalse: [ ^ self ].
	requestAnnouncement type = #before
		ifTrue: [ self beginImportFromSource ]
		ifFalse: [ self endImportFromSource ]
]

{ #category : 'accessing' }
AbWorkingDirectory >> importNestingCount [

	^ importNestingCount
]

{ #category : 'accessing' }
AbWorkingDirectory >> importNestingCount: anInteger [

	importNestingCount := anInteger
]

{ #category : 'initialization' }
AbWorkingDirectory >> initialize [

	importNestingCount := 0
]

{ #category : 'accessing' }
AbWorkingDirectory >> isImportingFromSource [

	^ self importNestingCount > 0
]

{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ topic workingDirectoryPath asFileReference
]

{ #category : 'accessing' }
AbWorkingDirectory >> safeTopicName [

	| safe |
	safe := topic title collect: [ :c |
		    (c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			    ifTrue: [ c ]
			    ifFalse: [ $- ] ].
	safe ifEmpty: [ safe := 'topic' ].
	^ safe
]

{ #category : 'accessing' }
AbWorkingDirectory >> sourcePath [

	^ self path / self srcDirectory
]

{ #category : 'accessing' }
AbWorkingDirectory >> srcDirectory [

	^ srcDirectory ifNil: [ self detectSrcDirectoryFromProjectMetafile ]
]

{ #category : 'accessing' }
AbWorkingDirectory >> srcDirectory: aString [

	srcDirectory := aString
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic [
	^ topic
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'subscribing' }
AbWorkingDirectory >> subscribeToSisServerImportEvents [

	| server |
	server := SisServer current.
	server unsubscribe: self.
	server
		subscribeOnRequest: [ :ann | self handleSisRequestAnnouncement: ann ]
		for: self
]

{ #category : 'subscribing' }
AbWorkingDirectory >> unsubscribeFromSisServerImportEvents [

	SisServer current unsubscribe: self
]
