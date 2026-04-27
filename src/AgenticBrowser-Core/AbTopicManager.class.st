Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics',
		'announcer'
	],
	#classInstVars : [
		'uniqueInstance'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'testing' }
AbTopicManager class >> resetInstance [

	uniqueInstance := nil
]

{ #category : 'instance creation' }
AbTopicManager class >> uniqueInstance [

	^ uniqueInstance ifNil: [ uniqueInstance := self new ]
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

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := Dictionary new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	topics removeKey: anAbTopic topicId ifAbsent: []
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics values asArray
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics valuesDo: aBlock
]

{ #category : 'accessing' }
AbTopicManager >> at: aTopicId [

	^ topics at: aTopicId ifAbsent: [ nil ]
]
