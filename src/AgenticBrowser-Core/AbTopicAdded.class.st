Class {
	#name : 'AbTopicAdded',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicAdded >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicAdded >> topic: anAbTopic [
	topic := anAbTopic
]
