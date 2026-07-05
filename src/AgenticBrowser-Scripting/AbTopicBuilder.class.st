"
I configure a single topic within an orchestration step.

I am created via #topicBy: in the DSL builder. The block sets my title, prompt, and optional goal.
I lazily create an AbTopic and apply configuration when #prepareWith:for: is called by the step
before running.

Responsibility:
- Hold topic title, initial prompt text, and optional goal description
- Lazily instantiate an AbTopic
- Apply agent arguments and shared working directory to the topic
- Configure auto-approval settings so the orchestration runs headlessly

Collaborators:
- AbTopicOrchestrationBuilder: creates me via #topicBy:
- AbOrchestrationStep: calls #prepareWith:for: to configure and register the topic
- AbCodingAgentBuilder: provides agent arguments
- AbTopic: the underlying domain object I configure

Public API and Key Messages:
- #title: aString - display name shown in the topic sidebar (optional; defaults to prompt)
- #prompt: aString - initial message sent to the agent
- #goal: aString - completion condition; topic runs until #goalAchieved
"
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

{ #category : 'factory' }
AbTopicBuilder >> createTopic [
	^ AbTopic new
]

{ #category : 'accessing' }
AbTopicBuilder >> goal [
	^ goalDescription
]

{ #category : 'accessing' }
AbTopicBuilder >> goal: aString [
	goalDescription := aString
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

{ #category : 'accessing' }
AbTopicBuilder >> prompt [
	^ prompt
]

{ #category : 'accessing' }
AbTopicBuilder >> prompt: aString [
	prompt := aString
]

{ #category : 'actions' }
AbTopicBuilder >> resetForRerun [
	topic := nil
]

{ #category : 'accessing' }
AbTopicBuilder >> title [
	^ self topic title
]

{ #category : 'accessing' }
AbTopicBuilder >> title: aString [
	self topic title: aString
]

{ #category : 'accessing' }
AbTopicBuilder >> topic [
	^ topic ifNil: [topic := self createTopic]
]
