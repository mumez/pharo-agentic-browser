Class {
	#name : 'AbTopicRemoved',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicRemoved >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicRemoved >> topic: anAbTopic [
	topic := anAbTopic
]
