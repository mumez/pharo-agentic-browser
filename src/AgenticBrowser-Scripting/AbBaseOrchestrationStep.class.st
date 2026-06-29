"
I am the abstract root for all orchestration steps.

I hold the orchestration context and provide the shared #on: factory and #orchestration accessor.
Subclasses are AbOrchestrationStep (topic-level steps) and AbOrchestrationGroupStep (group-level steps).

Collaborators:
- AbBaseOrchestration (subclasses): provides logger, settings, and shared state
- AbSettings: accessed via the orchestration; falls back to AbSettings default when orchestration is nil

Public API and Key Messages:
- #on: anOrchestration - class-side factory; create a step linked to the given orchestration
- #run - execute this step (subclass responsibility)
- #orchestration - the parent orchestration context
- #logger - delegates to orchestration logger
- #settings - delegates to orchestration settings; falls back to AbSettings default
"
Class {
	#name : 'AbBaseOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbBaseOrchestrationStep class >> on: anOrchestration [
	^ self new
		orchestration: anOrchestration;
		yourself
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> orchestration: anOrchestration [
	orchestration := anOrchestration
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> logger [
	^ self orchestration logger
]

{ #category : 'running' }
AbBaseOrchestrationStep >> run [
	self subclassResponsibility
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> settings [
	^ orchestration
		ifNil: [ AbSettings default ]
		ifNotNil: [ :orch | orch settings ]
]
