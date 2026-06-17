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
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders with: anAgentConfig [
	steps add: (AbSequentialStep new
		topicBuilders: aCollectionOfTopicBuilders;
		agentConfig: anAgentConfig;
		yourself)
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> seq: aCollectionOfTopicBuilders [
	self seq: aCollectionOfTopicBuilders with: nil
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders with: anAgentConfig [
	steps add: (AbParallelStep new
		topicBuilders: aCollectionOfTopicBuilders;
		agentConfig: anAgentConfig;
		yourself)
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> para: aCollectionOfTopicBuilders [
	self para: aCollectionOfTopicBuilders with: nil
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> topicBy: aBlock [
	^ AbTopicBuilder new configure: aBlock
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> agentBy: aBlock [
	^ AbAgentBuilder new configure: aBlock
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> agent [
	^ AbAgentBuilder new
]

{ #category : 'building' }
AbTopicOrchestrationBuilder >> steps [
	^ steps
]
