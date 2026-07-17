"
I am the singleton registry for active AbBaseOrchestration instances.

Responsibility:
- Maintain a Dictionary of orchestrations keyed by their id.
- Allow registration and deregistration of orchestrations.
- Provide lookup by orchestration id.
- Support bulk release of all registered orchestrations.

Public API and Key Messages:
- AbOrchestrationManager class>>#default - Access the global singleton.
- AbOrchestrationManager class>>#forTest - Isolated instance for the test suite.
- #register: anOrchestration - Register and return its id.
- #unregister: anOrchestration - Remove from registry.
- #orchestrationAt: anId - Look up by id; returns nil if absent.
- #release - Clear all registered orchestrations.

Internal Representation:
- orchestrations - Dictionary keyed by id String, valued by AbBaseOrchestration subinstances.
- default (class inst var) - The global singleton instance.
- forTest (class inst var) - Isolated instance used by the test suite; does not affect the global instance.
"
Class {
	#name : 'AbOrchestrationManager',
	#superclass : 'Object',
	#instVars : [
		'orchestrations'
	],
	#classInstVars : [
		'default',
		'forTest'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationManager class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'instance creation' }
AbOrchestrationManager class >> forTest [

	^ forTest ifNil: [ forTest := self new ]
]

{ #category : 'instance creation' }
AbOrchestrationManager class >> forTest: anInstance [

	forTest := anInstance
]

{ #category : 'class initialization' }
AbOrchestrationManager class >> initialize [

	default := forTest := nil
]

{ #category : 'initialization' }
AbOrchestrationManager >> initialize [

	orchestrations := Dictionary new
]

{ #category : 'accessing' }
AbOrchestrationManager >> orchestrations [

	^ orchestrations
]

{ #category : 'accessing' }
AbOrchestrationManager >> orchestrationAt: anId [

	^ self orchestrations at: anId ifAbsent: [ nil ]
]

{ #category : 'operations' }
AbOrchestrationManager >> register: anOrchestration [

	self orchestrations at: anOrchestration id put: anOrchestration.
	^ anOrchestration id
]

{ #category : 'operations' }
AbOrchestrationManager >> unregister: anOrchestration [

	self orchestrations removeKey: anOrchestration id ifAbsent: [ ]
]

{ #category : 'releasing' }
AbOrchestrationManager >> release [

	(self orchestrations select: [ :each | each isRunning not ])
		do: [ :each | self unregister: each ].
	^ self orchestrations isEmpty
]
