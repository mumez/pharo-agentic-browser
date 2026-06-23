Class {
	#name : 'AbTopicRemoved',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicRemoved class >> topic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'accessing' }
AbTopicRemoved >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicRemoved >> topic: anAbTopic [
	topic := anAbTopic
]
