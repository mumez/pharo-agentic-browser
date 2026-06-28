"
I am the abstract base for a step in an AbOrchestrationGroup.

Each step holds a collection of runnable items (AbTopicOrchestration or AbOrchestrationGroup)
and executes them either sequentially (AbOrchestrationGroupSequentialStep) or concurrently
(AbOrchestrationGroupParallelStep).

Responsibility:
- Hold the items to execute
- Hold the result produced by this step (stepResult)
- Define the #run protocol (subclasses implement it)

Collaborators:
- AbOrchestrationGroup: holds me and calls #run in order
- AbTopicOrchestration / AbOrchestrationGroup: my items (duck-typed: must respond to #run and #result)
"
Class {
	#name : 'AbOrchestrationGroupStep',
	#superclass : 'AbBaseOrchestrationStep',
	#instVars : [
		'items',
		'stepResult'
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

{ #category : 'accessing' }
AbOrchestrationGroupStep >> stepResult [
	^ stepResult
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> stepResult: aString [
	stepResult := aString
]

