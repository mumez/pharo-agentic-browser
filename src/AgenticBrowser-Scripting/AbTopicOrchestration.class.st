"
I represent a multi-topic orchestration that coordinates AI agent sessions in a structured workflow.

I am the root object of the Scripting DSL. I hold an ordered collection of steps (sequential or
parallel) and run them in order when #run is called.

Responsibility:
- Hold and execute an ordered list of AbOrchestrationStep instances
- Propagate results between steps
- Clean up topics from AbTopicManager after the run (unless lingerOrchestrationTopicsAfterRun is true)

Persistence, shared directory, naming, and debugging are inherited from AbBaseOrchestration.

Collaborators:
- AbTopicOrchestrationBuilder: builds my steps from a DSL block
- AbOrchestrationStep (subclasses): executed in sequence; each returns a result string
- AbSettings: provides default settings (timeouts, linger behavior)
- AbTopicManager: topics are registered to and optionally removed from it
- AgenticBrowser: class-side entry points #scriptBy: and #runBy: create me

Public API and Key Messages:
- #buildBy: aBlock - configure steps via DSL builder block
- #run - execute all steps in order; blocks until complete; returns final result
- #result - returns the result of the last completed step
- #save / #saveTo: - persist to disk via Fuel serialization (inherited)
- #explore - open inspector on orchestration state (inherited)
"
Class {
	#name : 'AbTopicOrchestration',
	#superclass : 'AbBaseOrchestration',
	#instVars : [
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'building' }
AbTopicOrchestration >> orchestrationBuilderClass [
	^ AbTopicOrchestrationBuilder
]

{ #category : 'running' }
AbTopicOrchestration >> removeTopicsFromManager [
	self steps do: [ :step |
		step topics do: [ :topic | self topicManager removeTopic: topic ] ]
]

{ #category : 'running' }
AbTopicOrchestration >> run [
	| stepResult |
	self logger debug: 'Orchestration run: start name=' , self name , ' steps=' , self steps size printString.
	stepResult := nil.
	[
		self steps do: [ :step |
			step previousStepResult: stepResult.
			stepResult := step run.
			step stepResult: stepResult ]
	] ensure: [
		self settings lingerOrchestrationTopicsAfterRun ifFalse: [ self removeTopicsFromManager ].
		self announcer announce: (AbOrchestrationEnded orchestration: self) ].
	self logger debug: 'Orchestration run: end name=' , self name.
	^ stepResult
]

{ #category : 'accessing' }
AbTopicOrchestration >> topicManager [
	^ AbTopicManager default
]
