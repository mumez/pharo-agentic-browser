Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [ 'topics' ],
	#classInstVars : [ 'uniqueInstance' ],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManager class >> uniqueInstance [

	^ uniqueInstance ifNil: [ uniqueInstance := self new ]
]

{ #category : 'testing' }
AbTopicManager class >> resetInstance [

	uniqueInstance := nil
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := OrderedCollection new
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics add: anAbTopic
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	topics remove: anAbTopic ifAbsent: []
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics do: aBlock
]
