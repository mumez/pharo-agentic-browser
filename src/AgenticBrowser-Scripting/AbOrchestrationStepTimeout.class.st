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
