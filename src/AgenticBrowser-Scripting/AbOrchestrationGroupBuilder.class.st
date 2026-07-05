"
I am the DSL builder for AbOrchestrationGroup.

I provide #para: and #seq: to add execution nodes, and factory methods #orchestrationBy:,
#singleTopicBy:agentBy:, and #orchestrationGroupBy: to create child orchestrations and groups.

Responsibility:
- Provide #para: and #seq: DSL entry points (each adds a node to the group)
- Provide #orchestrationBy: to create an AbTopicOrchestration via its own builder
- Provide #singleTopicBy:agentBy: as a shortcut to create an AbTopicOrchestration with a single sequential step containing one topic, and add it to the group as a sequential node
- Provide #orchestrationGroupBy: to create a nested AbOrchestrationGroup
- Provide #orchestrationLoadFrom: to load a previously saved AbTopicOrchestration and reset it for a fresh run
- Provide #orchestrationGroupLoadFrom: to load a previously saved AbOrchestrationGroup and reset it for a fresh run
- Provide #sharedDirectoryPath: to set a common working directory propagated to all items at run time

Collaborators:
- AbOrchestrationGroup: the group under construction (holds my nodes via #group)
- AbOrchestrationGroupParallelStep: created by #para:
- AbOrchestrationGroupSequentialStep: created by #seq: and #singleTopicBy:agentBy:
- AbTopicOrchestration: created by #orchestrationBy: and #singleTopicBy:agentBy:

Public API and Key Messages:
- #para: aCollection - add a parallel node containing the items in aCollection
- #seq: aCollection - add a sequential node containing the items in aCollection
- #orchestrationBy: aBlock - create AbTopicOrchestration; block receives AbTopicOrchestrationBuilder
- #singleTopicBy: topicBlock agentBy: agentBlock - shortcut: create AbTopicOrchestration with one sequential topic and add it to the group as a sequential node; topicBlock receives AbTopicBuilder, agentBlock receives AbCodingAgentBuilder
- #orchestrationGroupBy: aBlock - create nested AbOrchestrationGroup; block receives AbOrchestrationGroupBuilder
- #orchestrationLoadFrom: aFileReference - load a saved AbTopicOrchestration via Fuel and reset it (clears prior run results and cached topics) so it can be reused as a fresh item
- #orchestrationGroupLoadFrom: aFileReference - load a saved AbOrchestrationGroup via Fuel and reset it the same way
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

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationLoadFrom: aFileReference [
	^ (AbTopicOrchestration loadFrom: aFileReference)
		resetForRerun;
		yourself
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> orchestrationGroupLoadFrom: aFileReference [
	^ (AbOrchestrationGroup loadFrom: aFileReference)
		resetForRerun;
		yourself
]

{ #category : 'factory' }
AbOrchestrationGroupBuilder >> singleTopicBy: topicBuilderBlock agentBy: agentBuilderBlock [
    self seq: {
        self orchestrationBy: [ :b |
            b seq: {b topicBy: topicBuilderBlock}
		agentBy: agentBuilderBlock ]
    }
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
