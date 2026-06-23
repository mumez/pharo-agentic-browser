Class {
	#name : 'AbTopicAdded',
	#superclass : 'Announcement',
	#instVars : [
		'topic'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicAdded class >> topic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'accessing' }
AbTopicAdded >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicAdded >> topic: anAbTopic [
	topic := anAbTopic
]
