Class {
	#name : 'AbTopicAvailableCommandsChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'commands'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicAvailableCommandsChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicAvailableCommandsChanged >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicAvailableCommandsChanged >> commands [
	^ commands
]

{ #category : 'accessing' }
AbTopicAvailableCommandsChanged >> commands: aCollection [
	commands := aCollection
]
