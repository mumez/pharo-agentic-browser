Class {
	#name : 'AbTopicBuilder',
	#superclass : 'AbElementBuilder',
	#instVars : [
		'topic',
		'prompt'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbTopicBuilder >> goal [
	^ self topic topicGoal description
]

{ #category : 'accessing' }
AbTopicBuilder >> goal: aString [
	self topic topicGoal description: aString
]

{ #category : 'factory' }
AbTopicBuilder >> instantiateWith: anAgentConfig [
	| newTopic |
	newTopic := self topicClass new.
	newTopic agentArguments: anAgentConfig agentArguments.
	newTopic title: self topic title.
	self topic topicGoal description ifNotNil: [ :g |
		newTopic topicGoal description: g ].
	^ newTopic
]

{ #category : 'accessing' }
AbTopicBuilder >> topic [
	^ topic ifNil: [topic := self createTopic]
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
AbTopicBuilder >> title [
	^ self topic title
]

{ #category : 'accessing' }
AbTopicBuilder >> title: aString [
	self topic title: aString
]

{ #category : 'factory' }
AbTopicBuilder >> createTopic [
	^ AbTopic new
]
