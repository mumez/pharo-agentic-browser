"
I am a composite container of orchestration workflows that can be run in groups.

I hold an ordered list of AbOrchestrationGroupNode instances. When #run is called, I execute
each node in order. Each node runs its contained items either sequentially (AbOrchestrationGroupSeqNode)
or concurrently (AbOrchestrationGroupParaNode).

I announce AbOrchestrationEnded on my own announcer when all nodes complete, making me composable:
I can be nested inside another AbOrchestrationGroup as an item.

Responsibility:
- Hold an ordered list of AbOrchestrationGroupNode instances
- Execute nodes in sequence when #run is called
- Fire AbOrchestrationEnded on completion
- Expose #announcer so subscribers can react to completion

Collaborators:
- AbOrchestrationGroupBuilder: constructs me via #buildBy:
- AbOrchestrationGroupNode (subclasses): my execution nodes
- AbTopicOrchestration: leaf items inside nodes
- AbOrchestrationEnded: fired on completion

Public API and Key Messages:
- #buildBy: aBlock - configure nodes via DSL builder block
- #run - execute all nodes in order; blocks until complete; returns last node result
- #announcer - Announcer that fires AbOrchestrationEnded on run completion
- #nodes - the ordered collection of AbOrchestrationGroupNode
"
Class {
	#name : 'AbOrchestrationGroup',
	#superclass : 'Object',
	#instVars : [
		'nodes',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbOrchestrationGroup class >> buildBy: aBlock [
	^ self new buildBy: aBlock
]

{ #category : 'accessing' }
AbOrchestrationGroup >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'building' }
AbOrchestrationGroup >> buildBy: aBlock [
	| builder |
	builder := AbOrchestrationGroupBuilder on: self.
	aBlock value: builder
]

{ #category : 'accessing' }
AbOrchestrationGroup >> nodes [
	^ nodes ifNil: [ nodes := OrderedCollection new ]
]

{ #category : 'running' }
AbOrchestrationGroup >> run [
	| result |
	result := nil.
	[
		self nodes do: [ :node | result := node run ]
	] ensure: [
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	^ result
]
