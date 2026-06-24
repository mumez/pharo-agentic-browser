"
I signal that a topic in an orchestration step did not complete within the allowed timeout.

I carry the offending AbOrchestrationStep so callers can identify which step timed out.
"
Class {
	#name : 'AbOrchestrationStepTimeout',
	#superclass : 'Error',
	#instVars : [
		'step'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'instance creation' }
AbOrchestrationStepTimeout class >> step: anOrchestrationStep [
	^ self new step: anOrchestrationStep
]

{ #category : 'accessing' }
AbOrchestrationStepTimeout >> step [
	^ step
]

{ #category : 'accessing' }
AbOrchestrationStepTimeout >> step: anOrchestrationStep [
	step := anOrchestrationStep
]
