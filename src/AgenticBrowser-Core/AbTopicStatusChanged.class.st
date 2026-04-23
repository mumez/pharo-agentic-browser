Class {
	#name : 'AbTopicStatusChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicStatusChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicStatusChanged >> topic: anAbTopic [
	topic := anAbTopic
]
