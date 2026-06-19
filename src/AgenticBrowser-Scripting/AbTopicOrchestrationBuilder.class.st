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
AbTopicOrchestrationBuilder >> agent [
	^ self agentBy: [ :builder | ]
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> agentBy: aBlock [
	^ self agentBuilder buildBy: aBlock
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
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders with: anCodingAgentBuilder [
	steps add: (AbSequentialStep new
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: anCodingAgentBuilder;
		yourself)
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders [
	self seq: aCollectionOfTopicBuilders with: nil
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders with: anCodingAgentBuilder [
	steps add: (AbParallelStep new
		topicBuilders: aCollectionOfTopicBuilders;
		codingAgentBuilder: anCodingAgentBuilder;
		yourself)
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders [
	self para: aCollectionOfTopicBuilders with: nil
]

{ #category : 'building' }
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
AbTopicOrchestrationBuilder >> agentBuilder [
	^ self agentBuilderClass on: self
]

{ #category : 'private' }
AbTopicOrchestrationBuilder >> topicBuilder [
	^ self topicBuilderClass on: self
]
