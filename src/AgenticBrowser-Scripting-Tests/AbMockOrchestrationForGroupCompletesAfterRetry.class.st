"
I am a mock orchestration that never fires AbOrchestrationEnded on its first #run, then
succeeds on every subsequent #run. Used to test that #retry, called from an #onTimeout:
handler, re-runs a timed-out step until it completes.
"
Class {
	#name : 'AbMockOrchestrationForGroupCompletesAfterRetry',
	#superclass : 'Object',
	#instVars : [
		'announcer',
		'runCount'
	],
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'accessing' }
AbMockOrchestrationForGroupCompletesAfterRetry >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbMockOrchestrationForGroupCompletesAfterRetry >> name [
	^ 'mock-retry'
]

{ #category : 'accessing' }
AbMockOrchestrationForGroupCompletesAfterRetry >> result [
	^ 'retried-result'
]

{ #category : 'running' }
AbMockOrchestrationForGroupCompletesAfterRetry >> run [
	runCount := self runCount + 1.
	runCount = 1 ifTrue: [ ^ self ].
	self announcer announce: (AbOrchestrationEnded orchestration: self)
]

{ #category : 'accessing' }
AbMockOrchestrationForGroupCompletesAfterRetry >> runCount [
	^ runCount ifNil: [ 0 ]
]
