Class {
	#name : 'AbTopicGoal',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'description',
		'result',
		'whenAchieved'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicGoal class >> on: aTopic [

	^ self new topic: aTopic; yourself
]

{ #category : 'accessing' }
AbTopicGoal >> result [
	^ result
]

{ #category : 'accessing' }
AbTopicGoal >> result: aString [
	result := aString
]

{ #category : 'operations' }
AbTopicGoal >> checkAchievement [

	| file |
	file := self resultFile.
	file exists ifFalse: [ ^ false ].
	self result: file contents.
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
	^ self result notNil
]

{ #category : 'accessing' }
AbTopicGoal >> notificationPrompt [

	| basePrompt goalCommand |
	basePrompt := 'Goal has been set: ' , description
		, '. When the goal is achieved, summarize and report in result-'
		, self resultFileBasename
		, '. Keep retrying until the goal is achieved.'.
	goalCommand := self topic settings goalSettingsCommand.
	(goalCommand isNil or: [ goalCommand isEmpty ]) ifTrue: [ ^ basePrompt ].
	^ goalCommand , ' ' , basePrompt
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
AbTopicGoal >> fireWhenAchieved [

	self whenAchieved ifNotNil: [ :block | block cull: self ]
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
	whenAchieved := aBlock
]

{ #category : 'accessing' }
AbTopicGoal >> whenAchieved [
	^ whenAchieved
]
