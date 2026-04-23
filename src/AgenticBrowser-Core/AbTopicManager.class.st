Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics'
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

	topics add: anAbTopic
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
