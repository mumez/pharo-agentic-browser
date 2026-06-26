"
I am the abstract base for a node in an AbOrchestrationGroup.

Each node holds a collection of runnable items (AbTopicOrchestration or AbOrchestrationGroup)
and executes them either sequentially (AbOrchestrationGroupSeqNode) or concurrently
(AbOrchestrationGroupParaNode).

Responsibility:
- Hold the items to execute
- Define the #run protocol (subclasses implement it)

Collaborators:
- AbOrchestrationGroup: holds me and calls #run in order
- AbTopicOrchestration / AbOrchestrationGroup: my items (duck-typed: must respond to #run)
"
Class {
	#name : 'AbOrchestrationGroupNode',
	#superclass : 'Object',
	#instVars : [
		'items'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbOrchestrationGroupNode >> items [
	^ items ifNil: [ items := OrderedCollection new ]
]

{ #category : 'accessing' }
AbOrchestrationGroupNode >> items: aCollection [
	items := aCollection asOrderedCollection
]

{ #category : 'running' }
AbOrchestrationGroupNode >> run [
	self subclassResponsibility
]
