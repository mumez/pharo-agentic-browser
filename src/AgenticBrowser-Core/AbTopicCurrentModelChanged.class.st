Class {
	#name : 'AbTopicCurrentModelChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'model'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicCurrentModelChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicCurrentModelChanged >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicCurrentModelChanged >> model [
	^ model
]

{ #category : 'accessing' }
AbTopicCurrentModelChanged >> model: aString [
	model := aString
]
