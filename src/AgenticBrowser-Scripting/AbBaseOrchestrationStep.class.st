"
I am the abstract root for all orchestration steps.

I hold the orchestration context and provide the shared #on: factory and #orchestration accessor.
Subclasses are AbOrchestrationStep (topic-level steps) and AbOrchestrationGroupStep (group-level steps).

Collaborators:
- AbBaseOrchestration (subclasses): provides logger, settings, and shared state
- AbSettings: accessed via the orchestration; falls back to AbSettings default when orchestration is nil

Public API and Key Messages:
- #on: anOrchestration - class-side factory; create a step linked to the given orchestration
- #run - template method; runs #basicRun (subclass responsibility) and routes an unhandled AbOrchestrationStepTimeout to #onTimeoutBlock
- #basicRun - execute this step's actual work (subclass responsibility)
- #orchestration - the parent orchestration context
- #logger - delegates to orchestration logger
- #settings - delegates to orchestration settings; falls back to AbSettings default
- #onTimeout: aBlock - install a handler invoked with (self, anAbOrchestrationStepTimeout) instead of raising the debugger
- #retry - re-run this step from scratch (#run again); intended for use inside an #onTimeout: block
- #waitTimeoutSeconds: aNumber - shortcut to update this step's wait-timeout setting (subclass responsibility; resolves to the right AbSettings key)
- #lastError - the most recent error caused via #signalTimeout (nil if none)
- #isTimedOut - true if #lastError is an AbOrchestrationStepTimeout
"
Class {
	#name : 'AbBaseOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'onTimeoutBlock',
		'lastError'
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

{ #category : 'error handling' }
AbBaseOrchestrationStep >> signalTimeout [
	| timeout |
	timeout := AbOrchestrationStepTimeout step: self.
	self lastError: timeout.
	^ timeout signal
]

{ #category : 'error handling' }
AbBaseOrchestrationStep >> handleTimeout: anException [
	^ self onTimeoutBlock
		ifNil: [ anException pass ]
		ifNotNil: [ :aBlock | aBlock cull: self cull: anException ]
]

{ #category : 'testing' }
AbBaseOrchestrationStep >> isTimedOut [
	^ lastError isKindOf: AbOrchestrationStepTimeout
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> lastError [
	^ lastError
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> lastError: anException [
	lastError := anException
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> logger [
	^ self orchestration logger
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> onTimeout: aBlock [
	onTimeoutBlock := aBlock
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> onTimeoutBlock [
	^ onTimeoutBlock
]

{ #category : 'running' }
AbBaseOrchestrationStep >> run [
	lastError := nil.
	^ [ self basicRun ]
		on: AbOrchestrationStepTimeout
		do: [ :ex | self handleTimeout: ex ]
]

{ #category : 'running' }
AbBaseOrchestrationStep >> basicRun [
	self subclassResponsibility
]

{ #category : 'running' }
AbBaseOrchestrationStep >> retry [
	self resetForRetry.
	^ self run
]

{ #category : 'running' }
AbBaseOrchestrationStep >> resetForRetry [
	"Hook for subclasses to reset state before retry"
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> waitTimeoutSeconds: aNumber [
	self subclassResponsibility
]

{ #category : 'accessing' }
AbBaseOrchestrationStep >> settings [
	^ orchestration
		ifNil: [ AbSettings default ]
		ifNotNil: [ :orch | orch settings ]
]
