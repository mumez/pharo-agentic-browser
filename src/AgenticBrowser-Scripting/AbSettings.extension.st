Extension { #name : 'AbSettings' }

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> defaultLingerOrchestrationTopicsAfterRun [
	self isDefault ifFalse: [ ^ self class default defaultLingerOrchestrationTopicsAfterRun ].
	^ false
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> defaultOrchestrationGroupItemWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultOrchestrationGroupItemWaitTimeoutSeconds ].
	^ 3600
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

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> orchestrationGroupItemWaitTimeoutSeconds [
	^ self
		at: #orchestrationGroupItemWaitTimeoutSeconds
		ifAbsent: [ self defaultOrchestrationGroupItemWaitTimeoutSeconds ]
]

{ #category : '*AgenticBrowser-Scripting' }
AbSettings >> orchestrationGroupItemWaitTimeoutSeconds: anInteger [
	self at: #orchestrationGroupItemWaitTimeoutSeconds put: anInteger
]
