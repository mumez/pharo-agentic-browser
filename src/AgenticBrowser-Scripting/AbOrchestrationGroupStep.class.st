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

Public API and Key Messages:
- #on: anOrchestration - class-side factory (inherited from AbBaseOrchestrationStep)
- #items: aCollection - set the runnable items
- #basicRun - execute items (implemented by subclasses)
- #waitTimeoutSeconds: aNumber - shortcut for settings orchestrationGroupItemWaitTimeoutSeconds:
- #stepResult - result of this step after run
- #previousStepResult: aString - inject the previous step's result before running
"
Class {
	#name : 'AbOrchestrationGroupStep',
	#superclass : 'AbBaseOrchestrationStep',
	#instVars : [
		'items',
		'stepResult',
		'previousStepResult'
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
AbOrchestrationGroupStep >> previousStepResult [
	^ previousStepResult
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> previousStepResult: aString [
	previousStepResult := aString
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> stepResult [
	^ stepResult
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> stepResult: aString [
	stepResult := aString
]

{ #category : 'accessing' }
AbOrchestrationGroupStep >> waitTimeoutSeconds: aNumber [
	^ self settings orchestrationGroupItemWaitTimeoutSeconds: aNumber
]

{ #category : 'running' }
AbOrchestrationGroupStep >> resetForRerun [
	stepResult := nil.
	previousStepResult := nil.
	self items do: [ :item | item resetForRerun ]
]

{ #category : 'running' }
AbOrchestrationGroupStep >> resetForRetry [
	stepResult := nil.
	self items do: [ :item | item resetForRerun ]
]

