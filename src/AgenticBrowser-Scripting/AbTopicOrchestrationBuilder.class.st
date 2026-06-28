"
I am the DSL builder used inside an AbTopicOrchestration #buildBy: block.

I hold a reference to the AbTopicOrchestration being configured, so DSL calls for name,
sharedDirectoryPath, and settings delegate directly to that instance. I also accumulate
AbOrchestrationSequentialStep and AbOrchestrationParallelStep instances as the user calls #seq:agentBy: and
#para:agentBy:. When the block completes, AbTopicOrchestration reads my #steps collection.

Responsibility:
- Hold a reference to the AbTopicOrchestration under construction
- Provide the #name:, #sharedDirectoryPath:, #settings: DSL entry points
- Provide the #seq:agentBy: and #para:agentBy: DSL entry points
- Create AbTopicBuilder instances via #topicBy:
- Create AbCodingAgentBuilder instances via #agentBy:
- Collect steps in order for the orchestration

Collaborators:
- AbTopicOrchestration: holds me and reads my #steps after the build block completes
- AbOrchestrationSequentialStep / AbOrchestrationParallelStep: instantiated and added to steps
- AbTopicBuilder: created per #topicBy: call
- AbCodingAgentBuilder: created per #agentBy: call

Public API and Key Messages:
- #name: aString - set the orchestration name
- #sharedDirectoryPath: aString - set the shared working directory
- #settings: anAbSettings - set the orchestration settings
- #seq: topics agentBy: agentBlock - add a sequential step
- #seq: topics agentBy: agentBlock stepBy: stepBlock - add a sequential step; stepBlock receives the step for per-step configuration (e.g. sharedDirectoryPath:)
- #para: topics agentBy: agentBlock - add a parallel step
- #para: topics agentBy: agentBlock stepBy: stepBlock - add a parallel step; stepBlock receives the step for per-step configuration
- #topicBy: aBlock - create a topic builder for use inside step arrays
"
Class {
	#name : 'AbTopicOrchestrationBuilder',
	#superclass : 'Object',
	#instVars : [
		'orchestration'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbTopicOrchestrationBuilder class >> on: anOrchestration [
	^ self new
		orchestration: anOrchestration;
		yourself
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> agentBuilder [
	^ self agentBuilderClass on: self
]

{ #category : 'factory' }
AbTopicOrchestrationBuilder >> agentBuilderClass [
	^ AbCodingAgentBuilder
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> agentBy: aBlock [
	^ self agentBuilder buildBy: aBlock
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> name: aString [
	orchestration name: aString
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> orchestration: anOrchestration [
	orchestration := anOrchestration
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders agentBy: agentBuilderBlock [
	self para: aCollectionOfTopicBuilders agentBy: agentBuilderBlock stepBy: [ :step | ]
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders agentBy: agentBuilderBlock stepBy: stepBuilderBlock [
	| step |
	step := (AbOrchestrationParallelStep on: self orchestration)
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: (self agentBy: agentBuilderBlock);
		yourself.
	stepBuilderBlock value: step.
	self steps add: step
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders agentBy: agentBuilderBlock [
	self seq: aCollectionOfTopicBuilders agentBy: agentBuilderBlock stepBy: [ :step | ]
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders agentBy: agentBuilderBlock stepBy: stepBuilderBlock [
	| step |
	step := (AbOrchestrationSequentialStep on: self orchestration)
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: (self agentBy: agentBuilderBlock);
		yourself.
	stepBuilderBlock value: step.
	self steps add: step
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> settings: anAbSettings [
	orchestration settings: anAbSettings
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> sharedDirectoryPath: aString [
	orchestration sharedDirectoryPath: aString
]

{ #category : 'accessing' }
AbTopicOrchestrationBuilder >> steps [
	^ orchestration steps
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> topic [
	^ self topicBy: [ :builder | ]
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> topicBuilder [
	^ self topicBuilderClass on: self
]

{ #category : 'factory' }
AbTopicOrchestrationBuilder >> topicBuilderClass [
	^ AbTopicBuilder
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> topicBy: aBlock [
	^ self topicBuilder buildBy: aBlock
]
