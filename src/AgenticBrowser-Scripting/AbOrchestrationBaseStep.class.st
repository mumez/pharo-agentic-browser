"
I am the abstract root for all orchestration steps.

I hold the orchestration context and provide the shared #on: factory and #orchestration accessor.
Subclasses are AbOrchestrationStep (topic-level steps) and AbOrchestrationGroupStep (group-level steps).
"
Class {
	#name : 'AbOrchestrationBaseStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationBaseStep class >> on: anOrchestration [
	^ self new
		orchestration: anOrchestration;
		yourself
]

{ #category : 'accessing' }
AbOrchestrationBaseStep >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbOrchestrationBaseStep >> orchestration: anOrchestration [
	orchestration := anOrchestration
]

{ #category : 'accessing' }
AbOrchestrationBaseStep >> logger [
	^ self orchestration logger
]

{ #category : 'running' }
AbOrchestrationBaseStep >> run [
	self subclassResponsibility
]

{ #category : 'accessing' }
AbOrchestrationBaseStep >> settings [
	^ orchestration
		ifNil: [ AbSettings default ]
		ifNotNil: [ :orch | orch settings ]
]
