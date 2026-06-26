Extension { #name : 'AbSettings' }

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> defaultLingerOrchestrationTopicsAfterRun [
	self isDefault ifFalse: [ ^ self class default defaultLingerOrchestrationTopicsAfterRun ].
	^ false
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> defaultOrchestrationStepWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultOrchestrationStepWaitTimeoutSeconds ].
	^ 900
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> lingerOrchestrationTopicsAfterRun [
	^ self
		at: #lingerOrchestrationTopicsAfterRun
		ifAbsent: [ self defaultLingerOrchestrationTopicsAfterRun ]
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> lingerOrchestrationTopicsAfterRun: aBoolean [
	self at: #lingerOrchestrationTopicsAfterRun put: aBoolean
]

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
