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

{ #category : 'accessing' }
AbWorkingDirectory >> directoryName [

	^ self safeTopicName , '-' , (topic topicId copyFrom: 1 to: 8)
]

{ #category : 'operations' }
AbWorkingDirectory >> beginImportFromSource [

	importNestingCount := importNestingCount + 1
]

{ #category : 'operations' }
AbWorkingDirectory >> endImportFromSource [

	importNestingCount := (importNestingCount - 1) max: 0
]

{ #category : 'operations' }
AbWorkingDirectory >> ensureExists [

	self path ensureCreateDirectory
]

{ #category : 'initialization' }
AbWorkingDirectory >> initialize [

	importNestingCount := 0
]

{ #category : 'accessing' }
AbWorkingDirectory >> isImportingFromSource [

	^ importNestingCount > 0
]

{ #category : 'private' }
AbWorkingDirectory >> handleSisRequestAnnouncement: ann [

	| urlPath sourcePath |
	urlPath := ann teapotRequest url pathPrintString.
	urlPath = '/import-package' ifFalse: [ ^ self ].
	sourcePath := ann teapotRequest at: #path ifAbsent: [ ^ self ].
	self sourcePath fullName = sourcePath ifFalse: [ ^ self ].
	ann type = #before
		ifTrue: [ self beginImportFromSource ]
		ifFalse: [ self endImportFromSource ]
]

{ #category : 'operations' }
AbWorkingDirectory >> subscribeToSisServerImportEvents [

	| server |
	server := SisServer current.
	server unsubscribe: self.
	server
		subscribeOnRequest: [ :ann | self handleSisRequestAnnouncement: ann ]
		for: self
]

{ #category : 'operations' }
AbWorkingDirectory >> unsubscribeFromSisServerImportEvents [

	SisServer current unsubscribe: self
]


{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ topic workingDirectoryPath asFileReference
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
	^ srcDirectory := (configuredSrcDirectory isString and: [ configuredSrcDirectory isNotEmpty ])
		ifTrue: [ configuredSrcDirectory ]
		ifFalse: [ defaultSrcDirectory ]
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
AbWorkingDirectory >> sourcePath [

	^ self path / self srcDirectory
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
AbWorkingDirectory >> topic [
	^ topic
]

{ #category : 'accessing' }
AbWorkingDirectory >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'exporting' }
AbWorkingDirectory >> exportPackageNamed: aPackageName [
    self ensureExists.
    SisServer current handleExportPackage: {
		  'package_name' -> aPackageName.
		  'path' -> self sourcePath fullName } asDictionary
]
