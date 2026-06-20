Class {
	#name : 'AbTopicBuilder',
	#superclass : 'AbElementBuilder',
	#instVars : [
		'topic',
		'prompt',
		'goalDescription'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbTopicBuilder >> goal [
	^ goalDescription
]

{ #category : 'accessing' }
AbTopicBuilder >> goal: aString [
	goalDescription := aString
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

{ #category : 'actions' }
AbTopicBuilder >> prepareWith: aCodingAgentBuilder for: anOrchestrationStep [
	| topic |
	topic := self topic.
	topic agentArguments: aCodingAgentBuilder agentArguments.
	topic workingDirectoryPath: anOrchestrationStep sharedDirectoryPath.
	topic settings aiPermissionWaitTimeoutSeconds: 0.
	topic settings aiPermissionTimeoutOption: #allow_once.
	topic settings exportApprovalWaitTimeoutSeconds: 0.
	topic settings exportApprovalTimeoutOption: #allow_once.
	^ topic
]

{ #category : 'callbacks' }
AbTopicBuilder >> onConnected: aTopic [
	super onConnected: aTopic
]

{ #category : 'factory' }
AbTopicBuilder >> createTopic [
	^ AbTopic new
]
