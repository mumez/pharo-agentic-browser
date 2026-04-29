Class {
	#name : 'AbTopicStatusChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'status'
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

{ #category : 'accessing' }
AbTopicStatusChanged >> status [
	^ status
]

{ #category : 'accessing' }
AbTopicStatusChanged >> status: aSymbol [
	status := aSymbol
]
