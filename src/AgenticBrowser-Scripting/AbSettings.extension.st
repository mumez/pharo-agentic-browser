Extension { #name : 'AbSettings' }

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> orchestrationStepWaitTimeoutSeconds [
	^ self
		at: #orchestrationStepWaitTimeoutSeconds
		ifAbsent: [ self defaultOrchestrationStepWaitTimeoutSeconds ]
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> orchestrationStepWaitTimeoutSeconds: anInteger [
	self at: #orchestrationStepWaitTimeoutSeconds put: anInteger
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> defaultOrchestrationStepWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultOrchestrationStepWaitTimeoutSeconds ].
	^ 900
]
