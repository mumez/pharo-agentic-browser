"
I am the DSL builder for AbOrchestrationGroup.

I provide #para: and #seq: to add execution nodes, and factory methods #orchestrationBy: and
#orchestrationGroupBy: to create child orchestrations and groups.

Responsibility:
- Provide #para: and #seq: DSL entry points (each adds a node to the group)
- Provide #orchestrationBy: to create an AbTopicOrchestration via its own builder
- Provide #orchestrationGroupBy: to create a nested AbOrchestrationGroup
- Provide #sharedDirectoryPath: to set a common working directory propagated to all items at run time

Collaborators:
- AbOrchestrationGroup: the group under construction (holds my nodes via #group)
- AbOrchestrationGroupParallelStep: created by #para:
- AbOrchestrationGroupSequentialStep: created by #seq:
- AbTopicOrchestration: created by #orchestrationBy:

Public API and Key Messages:
- #para: aCollection - add a parallel node containing the items in aCollection
- #seq: aCollection - add a sequential node containing the items in aCollection
- #orchestrationBy: aBlock - create AbTopicOrchestration; block receives AbTopicOrchestrationBuilder
- #orchestrationGroupBy: aBlock - create nested AbOrchestrationGroup; block receives AbOrchestrationGroupBuilder
- #sharedDirectoryPath: aString - set the shared working directory for all items in the group
"
Class {
	#name : 'AbOrchestrationGroupBuilder',
	#superclass : 'Object',
	#instVars : [
		'group'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationGroupBuilder class >> on: anOrchestrationGroup [
	^ self new
		group: anOrchestrationGroup;
		yourself
]

{ #category : 'accessing' }
AbOrchestrationGroupBuilder >> group [
	^ group
]

{ #category : 'accessing' }
AbOrchestrationGroupBuilder >> group: anOrchestrationGroup [
	group := anOrchestrationGroup
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationBy: aBlock [
	^ AbTopicOrchestration buildBy: aBlock
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationGroupBy: aBlock [
	^ AbOrchestrationGroup buildBy: aBlock
]

{ #category : 'building' }
AbOrchestrationGroupBuilder >> para: aCollection [
	| node |
	node := AbOrchestrationGroupParallelStep new
		orchestration: self group;
		items: aCollection;
		yourself.
	self group steps add: node
]

{ #category : 'accessing' }
AbOrchestrationGroupBuilder >> sharedDirectoryPath: aString [
	self group sharedDirectoryPath: aString
]

{ #category : 'building' }
AbOrchestrationGroupBuilder >> seq: aCollection [
	| node |
	node := AbOrchestrationGroupSequentialStep new
		orchestration: self group;
		items: aCollection;
		yourself.
	self group steps add: node
]
