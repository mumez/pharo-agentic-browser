"
I am the abstract base for a step in an AbOrchestrationGroup.

Each step holds a collection of runnable items (AbTopicOrchestration or AbOrchestrationGroup)
and executes them either sequentially (AbOrchestrationGroupSequentialStep) or concurrently
(AbOrchestrationGroupParallelStep).

Responsibility:
- Hold the items to execute
- Define the #run protocol (subclasses implement it)

Collaborators:
- AbOrchestrationGroup: holds me and calls #run in order
- AbTopicOrchestration / AbOrchestrationGroup: my items (duck-typed: must respond to #run)
"
Class {
	#name : 'AbOrchestrationGroupStep',
	#superclass : 'AbBaseOrchestrationStep',
	#instVars : [
		'items'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbOrchestrationGroupStep >> items [
	^ items ifNil: [ items := OrderedCollection new ]
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> items: aCollection [
	items := aCollection asOrderedCollection
]

