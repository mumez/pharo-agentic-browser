Class {
	#name : 'AbTopicGoal',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'description',
		'achieved',
		'whenAchievedBlock'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicGoal class >> on: aTopic [

	^ self new topic: aTopic; yourself
]

{ #category : 'accessing' }
AbTopicGoal >> achieved [
	^ achieved
]

{ #category : 'accessing' }
AbTopicGoal >> achieved: aString [
	achieved := aString
]

{ #category : 'operations' }
AbTopicGoal >> checkAchievement [

	| file |
	file := self resultFile.
	file exists ifFalse: [ ^ false ].
	self achieved: file contents.
	file delete.
	^ true
]

{ #category : 'accessing' }
AbTopicGoal >> description [
	^ description
]

{ #category : 'accessing' }
AbTopicGoal >> description: aString [
	description := aString
]

{ #category : 'testing' }
AbTopicGoal >> isAchieved [
	^ self achieved notNil
]

{ #category : 'accessing' }
AbTopicGoal >> notificationPrompt [

	^ 'Goal has been set: ' , description
		, '. When the goal is achieved, summarize and report in result-'
		, self resultFileBasename
		, '. Keep retrying until the goal is achieved.'
]

{ #category : 'accessing' }
AbTopicGoal >> resultFile [

	^ topic workingDirectory path / self resultFileBasename
]

{ #category : 'accessing' }
AbTopicGoal >> resultFileBasename [

	^ 'result-' , topic topicId , '.md'
]

{ #category : 'operations' }
AbTopicGoal >> runWhenAchievedBlock [

	self whenAchievedBlock ifNotNil: [ :block | block value ]
]

{ #category : 'accessing' }
AbTopicGoal >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicGoal >> topic: anAbTopic [
	topic := anAbTopic
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchieved: aBlock [
	whenAchievedBlock := aBlock
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchievedBlock [
	^ whenAchievedBlock
]
