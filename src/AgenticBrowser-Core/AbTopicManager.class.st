Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics',
		'announcer'
	],
	#classInstVars : [
		'default',
		'forTest'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManager class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
AbTopicManager class >> default: anInstance [

	default := anInstance
]

{ #category : 'persistence' }
AbTopicManager class >> defaultFileReference [

	^ AbSettings defaultAgenticBrowserRootDirectory / self fileName
]

{ #category : 'persistence' }
AbTopicManager class >> fileName [

	^ 'ab-topics.fuel'
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest [

	^ forTest ifNil: [ forTest := self new ]
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest: anInstance [

	forTest := anInstance
]

{ #category : 'fuel' }
AbTopicManager class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' )
]

{ #category : 'class initialization' }
AbTopicManager class >> initialize [

	default ifNotNil: [ default cleanupAllTopics ].
	default := forTest := nil
]

{ #category : 'persistence' }
AbTopicManager class >> load [

	self defaultFileReference exists ifFalse: [ ^ self ].
	default ifNotNil: [ default cleanupAllTopics ].
	default := self loadFrom: self defaultFileReference
]

{ #category : 'persistence' }
AbTopicManager class >> loadFrom: aFileReference [

	^ FLMaterializer materializeFromFileNamed: aFileReference fullName
]

{ #category : 'persistence' }
AbTopicManager class >> save [

	self saveTo: self defaultFileReference
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference [

	self saveTo: aFileReference manager: self default
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference manager: aManager [

	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: aManager toFileNamed: aFileReference fullName
]

{ #category : 'instance creation' }
AbTopicManager class >> uniqueInstance [

	^ self default
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics at: anAbTopic topicId put: anAbTopic.
	self announcer announce: (AbTopicAdded new topic: anAbTopic; yourself)
]

{ #category : 'accessing' }
AbTopicManager >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbTopicManager >> at: aTopicId [

	^ topics at: aTopicId ifAbsent: [ nil ]
]

{ #category : 'operations' }
AbTopicManager >> cleanupAllTopics [

	topics valuesDo: [ :topic | self teardownTopic: topic ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := Dictionary new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	self teardownTopic: anAbTopic.
	topics removeKey: anAbTopic topicId ifAbsent: []
]

{ #category : 'operations' }
AbTopicManager >> subscribeAllTopicsToSisServer [

	topics valuesDo: [ :t | t workingDirectory subscribeToSisServerImportEvents ]
]

{ #category : 'private' }
AbTopicManager >> teardownTopic: aTopic [

	aTopic stopWatching.
	aTopic workingDirectory unsubscribeFromSisServerImportEvents.
	[ aTopic disconnect ] on: Error do: [ :e | "ignore disconnect errors" ]
]

{ #category : 'accessing' }
AbTopicManager >> topicForWorkingDirectoryPath: aString [

	| lookupPath |
	lookupPath := aString asFileReference fullName.
	^ topics values
		detect: [ :each |
			each workingDirectoryPath asFileReference fullName = lookupPath ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics values asArray
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics valuesDo: aBlock
]

{ #category : 'operations' }
AbTopicManager >> unsubscribeAllTopicsFromSisServer [

	topics valuesDo: [ :t | t workingDirectory unsubscribeFromSisServerImportEvents ]
]
