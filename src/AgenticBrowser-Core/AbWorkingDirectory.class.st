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
