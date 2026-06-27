"
I am the abstract base class for orchestration objects.

I provide shared identity, naming, settings, logging, and announcement infrastructure
used by both AbTopicOrchestration and AbOrchestrationGroup.

Responsibility:
- Hold a stable UUID as identity (id)
- Hold a human-readable name (name)
- Hold a settings copy (settings)
- Provide a shared logger instance (logger)
- Provide an announcer for lifecycle events (announcer)

Collaborators:
- AbSettings: provides default settings
- AbLocalLogger: default logger implementation
- AbOrchestrationEnded: announced on run completion by subclasses
"
Class {
	#name : 'AbBaseOrchestration',
	#superclass : 'Object',
	#instVars : [
		'id',
		'name',
		'settings',
		'logger',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'fuel' }
AbBaseOrchestration class >> fuelIgnoredInstanceVariableNames [
	^ #( 'logger' 'announcer' )
]

{ #category : 'accessing' }
AbBaseOrchestration >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> id [
	^ id ifNil: [ id := UUID new asString36 ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> name [
	^ name ifNil: [ name := 'orchestration' ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> name: aString [
	name := aString
]

{ #category : 'accessing' }
AbBaseOrchestration >> settings [
	^ settings ifNil: [ settings := AbSettings defaultCopied ]
]

{ #category : 'accessing' }
AbBaseOrchestration >> settings: anAbSettings [
	settings := anAbSettings
]
