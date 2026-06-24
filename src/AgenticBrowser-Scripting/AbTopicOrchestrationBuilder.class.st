"
I am the DSL builder used inside an AbTopicOrchestration #buildBy: block.

I accumulate AbSequentialStep and AbParallelStep instances as the user calls #seq:agentBy: and
#para:agentBy:. When the block completes, AbTopicOrchestration reads my #steps collection.

Responsibility:
- Provide the #seq:agentBy: and #para:agentBy: DSL entry points
- Create AbTopicBuilder instances via #topicBy:
- Create AbCodingAgentBuilder instances via #agentBy:
- Collect steps in order for the orchestration

Collaborators:
- AbTopicOrchestration: reads my #steps after the build block completes
- AbSequentialStep / AbParallelStep: instantiated and added to steps
- AbTopicBuilder: created per #topicBy: call
- AbCodingAgentBuilder: created per #agentBy: call

Public API and Key Messages:
- #seq: topics agentBy: agentBlock - add a sequential step
- #para: topics agentBy: agentBlock - add a parallel step
- #topicBy: aBlock - create a topic builder for use inside step arrays
"
Class {
	#name : 'AbTopicOrchestrationBuilder',
	#superclass : 'Object',
	#instVars : [
		'steps'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'initialization' }
AbTopicOrchestrationBuilder >> initialize [
	super initialize.
	steps := OrderedCollection new.
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> topic [
	^ self topicBy: [ :builder | ]
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> topicBy: aBlock [
	^ self topicBuilder buildBy: aBlock
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders agentBy: aBlock [
	self steps add: (AbSequentialStep new
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: (self agentBy: aBlock);
		yourself)
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders agentBy: aBlock [
	self steps add: (AbParallelStep new
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: (self agentBy: aBlock);
		yourself)
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> steps [
	^ steps
]

{ #category : 'factory' }
AbTopicOrchestrationBuilder >> agentBuilderClass [
	^ AbCodingAgentBuilder
]

{ #category : 'factory' }
AbTopicOrchestrationBuilder >> topicBuilderClass [
	^ AbTopicBuilder
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> agentBy: aBlock [
	^ self agentBuilder buildBy: aBlock
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> agentBuilder [
	^ self agentBuilderClass on: self
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> topicBuilder [
	^ self topicBuilderClass on: self
]
