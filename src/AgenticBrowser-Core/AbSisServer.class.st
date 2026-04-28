Class {
	#name : 'AbSisServer',
	#superclass : 'SisServer',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'system startup' }
AbSisServer class >> startUp: isImageStarting [

	(Delay forSeconds: 3) wait.
	SisServer current stop.
	super startUp: isImageStarting
]

{ #category : 'handling' }
AbSisServer >> handleImportPackage: request [

	^ self
		withImportGuardForRequest: request
		do: [ super handleImportPackage: request ]
]

{ #category : 'private' }
AbSisServer >> withImportGuardForRequest: request do: aBlock [

	| sourcePath topic |
	sourcePath := request at: #path.
	topic := AbTopicManager uniqueInstance
		         topicForWorkingDirectoryPath: sourcePath.
	topic ifNil: [ ^ aBlock value ].
	topic beginImportFromSource.
	^ [ aBlock value ] ensure: [ topic endImportFromSource ]
]
