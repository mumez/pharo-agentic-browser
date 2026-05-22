Class {
	#name : 'AbTopicCurrentModeChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'mode'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicCurrentModeChanged >> mode [
	^ mode
]

{ #category : 'accessing' }
AbTopicCurrentModeChanged >> mode: aString [
	mode := aString
]

{ #category : 'accessing' }
AbTopicCurrentModeChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicCurrentModeChanged >> topic: anAbTopic [
	topic := anAbTopic
]
