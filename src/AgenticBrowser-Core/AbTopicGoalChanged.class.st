Class {
	#name : 'AbTopicGoalChanged',
	#superclass : 'Announcement',
	#instVars : [
		'topic',
		'goal'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'accessing' }
AbTopicGoalChanged >> goal [
	^ goal
]

{ #category : 'accessing' }
AbTopicGoalChanged >> goal: aString [
	goal := aString
]

{ #category : 'accessing' }
AbTopicGoalChanged >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoalChanged >> topic: anAbTopic [
	topic := anAbTopic
]
