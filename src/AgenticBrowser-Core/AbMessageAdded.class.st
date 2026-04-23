Class {
	#name : 'AbMessageAdded',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'message'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbMessageAdded >> message [
	^ message
]

{ #category : 'accessing' }
AbMessageAdded >> message: anAbMessage [
	message := anAbMessage
]

{ #category : 'accessing' }
AbMessageAdded >> topic [
	^ topic
]

{ #category : 'accessing' }
AbMessageAdded >> topic: anAbTopic [
	topic := anAbTopic
]
