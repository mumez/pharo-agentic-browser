"
I am a composite container of orchestration workflows that can be run in groups.

I hold an ordered list of AbOrchestrationGroupStep instances. When #run is called, I execute
each step in order. Each step runs its contained items either sequentially (AbOrchestrationGroupSequentialStep)
or concurrently (AbOrchestrationGroupParallelStep).

I announce AbOrchestrationEnded on my own announcer when all steps complete, making me composable:
I can be nested inside another AbOrchestrationGroup as an item.

Responsibility:
- Hold an ordered list of AbOrchestrationGroupStep instances
- Execute steps in sequence when #run is called
- Fire AbOrchestrationEnded on completion
- Expose #announcer so subscribers can react to completion

Collaborators:
- AbOrchestrationGroupBuilder: constructs me via #buildBy:
- AbOrchestrationGroupStep (subclasses): my execution steps
- AbTopicOrchestration: leaf items inside steps
- AbOrchestrationEnded: fired on completion

Public API and Key Messages:
- #buildBy: aBlock - configure steps via DSL builder block
- #run - execute all steps in order; blocks until complete; returns last step result
- #announcer - Announcer that fires AbOrchestrationEnded on run completion
- #steps - the ordered collection of AbOrchestrationGroupStep
"
Class {
	#name : 'AbOrchestrationGroup',
	#superclass : 'AbBaseOrchestration',
	#instVars : [
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbOrchestrationGroup >> orchestrationBuilderClass [
	^ AbOrchestrationGroupBuilder
]

{ #category : 'running' }
AbOrchestrationGroup >> run [
	| result |
	result := nil.
	[
		self steps do: [ :node | result := node run ]
	] ensure: [
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	^ result
]
