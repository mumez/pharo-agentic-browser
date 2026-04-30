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
AbTopicManager class >> forTest [

	^ forTest ifNil: [ forTest := self new ]
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest: anInstance [

	forTest := anInstance
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

	topics valuesDo: [ :topic |
		topic stopWatching.
		topic workingDirectory unsubscribeFromSisServerImportEvents.
		[ topic disconnect ] on: Error do: [ :e | "ignore disconnect errors" ] ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := Dictionary new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	anAbTopic stopWatching.
	anAbTopic workingDirectory unsubscribeFromSisServerImportEvents.
	[ anAbTopic disconnect ] on: Error do: [ :e | "ignore disconnect errors" ].
	topics removeKey: anAbTopic topicId ifAbsent: []
]

{ #category : 'operations' }
AbTopicManager >> subscribeAllTopicsToSisServer [

	topics valuesDo: [ :t | t workingDirectory subscribeToSisServerImportEvents ]
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
