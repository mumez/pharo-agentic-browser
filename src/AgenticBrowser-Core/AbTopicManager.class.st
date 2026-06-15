"
I am the singleton registry and persistence manager for all AbTopic instances.

Responsibility:
- I maintain the collection of active topics keyed by their topicId.
- I persist topics to and load them from a Fuel binary file (ab-topics.fuel).
- I announce AbTopicAdded when a topic is registered.
- I clean up (stop watching, disconnect) topics on removal or image re-initialization.
- I provide topic lookup by topicId, working directory path, and name.

Collaborators:
- AbTopic: I own and lifecycle-manage all topic instances.
- AbTopicAdded: I announce it when a new topic is added.
- FLSerializer / FLMaterializer: I use the Fuel framework for binary serialization.

Public API and Key Messages:
- AbTopicManager class>>#default - Access the global singleton.
- AbTopicManager class>>load / #save - Load from / save to ab-topics.fuel.
- #addTopic: - Register a topic and announce AbTopicAdded.
- #removeTopic: - Teardown and deregister a topic.
- #topics - All registered topics as an Array.
- #topicNamed: - Look up the first topic by name (lexicographic topicId order).
- #topicForWorkingDirectoryPath: - Look up a topic by its working directory path.

Internal Representation:
- topics - Dictionary keyed by topicId String, valued by AbTopic.
- announcer - Lazy Announcer; excluded from Fuel and recreated lazily after load.
- default (class inst var) - The global singleton instance.
- forTest (class inst var) - Isolated instance used by the test suite; does not affect the global instance.

Implementation Points:
- announcer is excluded from Fuel serialization; subscribers must re-subscribe after each load.
- #cleanupAllTopics stops watchers and disconnects agents; called before replacing the default instance on load.
"
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

	self default save
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference [

	self default saveTo: aFileReference
]

{ #category : 'persistence' }
AbTopicManager >> save [

	self saveTo: self class defaultFileReference
]

{ #category : 'persistence' }
AbTopicManager >> saveTo: aFileReference [

	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: self toFileNamed: aFileReference fullName
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
AbTopicManager >> startAllTopicsWatching [

	topics valuesDo: [ :t | t startWatching ]
]

{ #category : 'private' }
AbTopicManager >> teardownTopic: aTopic [

	aTopic stopWatching.
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
AbTopicManager >> topicNamed: aString [

	| matches |
	matches := self topicsNamed: aString.
	matches ifEmpty: [ ^ nil ].
	^ (matches asSortedCollection: [ :a :b | a topicId < b topicId ]) first
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics values asArray
]

{ #category : 'accessing' }
AbTopicManager >> topicsNamed: aString [

	^ topics values select: [ :each | each name = aString ]
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics valuesDo: aBlock
]

{ #category : 'operations' }
AbTopicManager >> stopAllTopicsWatching [

	topics valuesDo: [ :t | t stopWatching ]
]
