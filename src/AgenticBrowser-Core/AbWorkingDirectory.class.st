Class {
	#name : 'AbWorkingDirectory',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'importNestingCount'
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
	self path fullName = sourcePath ifFalse: [ ^ self ].
	ann type = #before
		ifTrue: [ self beginImportFromSource ]
		ifFalse: [ self endImportFromSource ]
]

{ #category : 'operations' }
AbWorkingDirectory >> subscribeToSisServerImportEvents [

	SisServer current announcer unsubscribe: self.
	SisServer current announcer
		when: SisRequestAnnouncement
		do: [ :ann | self handleSisRequestAnnouncement: ann ]
		for: self
]

{ #category : 'operations' }
AbWorkingDirectory >> unsubscribeFromSisServerImportEvents [

	SisServer current announcer unsubscribe: self
]


{ #category : 'accessing' }
AbWorkingDirectory >> path [

	^ topic workingDirectoryPath asFileReference
]

{ #category : 'operations' }
AbWorkingDirectory >> runAllTests [

	^ String streamContents: [ :s |
		  topic matchingPackageNames do: [ :pkg |
			  | result |
			  result := self runTests: pkg.
			  s
				  nextPutAll: pkg;
				  nextPutAll: ': ';
				  nextPutAll: (result at: 'result' ifAbsent: [ 'error' ]);
				  cr ] ]
]

{ #category : 'operations' }
AbWorkingDirectory >> runTests: aPackageName [

	^ SisServer current handleRunPackageTest: {
		  'package_name' -> aPackageName } asDictionary
]

{ #category : 'accessing' }
AbWorkingDirectory >> safeTopicName [

	| safe |
	safe := topic title collect: [ :c |
		    (c isAlphaNumeric or: [ c = $- or: [ c = $_ ] ])
			    ifTrue: [ c ]
			    ifFalse: [ $- ] ].
	safe isEmpty ifTrue: [ safe := 'topic' ].
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
