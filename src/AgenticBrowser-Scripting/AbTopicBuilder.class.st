Class {
	#name : 'AbTopicBuilder',
	#superclass : 'AbElementBuilder',
	#instVars : [
		'title',
		'goal',
		'prompt',
		'topicClass'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbTopicBuilder >> title [
	^ title
]

{ #category : 'accessing' }
AbTopicBuilder >> title: aString [
	title := aString
]

{ #category : 'accessing' }
AbTopicBuilder >> goal [
	^ goal
]

{ #category : 'accessing' }
AbTopicBuilder >> goal: aString [
	goal := aString
]

{ #category : 'accessing' }
AbTopicBuilder >> prompt [
	^ prompt
]

{ #category : 'accessing' }
AbTopicBuilder >> prompt: aString [
	prompt := aString
]

{ #category : 'accessing' }
AbTopicBuilder >> topicClass [
	^ topicClass ifNil: [ topicClass := self defaultTopicClass ]
]

{ #category : 'accessing' }
AbTopicBuilder >> topicClass: aClass [
	topicClass := aClass
]

{ #category : 'defaults' }
AbTopicBuilder >> defaultTopicClass [
	^ AbTopic
]


{ #category : 'factory' }
AbTopicBuilder >> instantiateWith: anAgentConfig [
	| topic |
	topic := self topicClass new.
	topic agentArguments: anAgentConfig agentArguments.
	self title ifNotNil: [ topic title: self title ].
	self goal ifNotNil: [ topic topicGoal description: self goal ].
	^ topic
]
