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

	topics add: anAbTopic.
	self announcer announce: (AbTopicAdded new topic: anAbTopic; yourself)
]

{ #category : 'accessing' }
AbTopicManager >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := OrderedCollection new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	topics remove: anAbTopic ifAbsent: []
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics do: aBlock
]
