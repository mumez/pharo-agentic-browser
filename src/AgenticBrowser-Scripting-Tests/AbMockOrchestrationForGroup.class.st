"
I am a lightweight mock orchestration used in AbOrchestrationGroup tests.
I skip all real topic/agent machinery and just record that I was run.
"
Class {
	#name : 'AbMockOrchestrationForGroup',
	#superclass : 'Object',
	#instVars : [
		'runResult',
		'runCount',
		'runDelay',
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'instance creation' }
AbMockOrchestrationForGroup class >> withResult: aString [
	^ self new runResult: aString
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'running' }
AbMockOrchestrationForGroup >> run [
	runCount := self runCount + 1.
	runDelay ifNotNil: [ (Delay forMilliseconds: runDelay) wait ].
	self announcer announce: (AbOrchestrationEnded orchestration: self).
	^ runResult
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runCount [
	^ runCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runDelay: aNumber [
	runDelay := aNumber
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runResult [
	^ runResult
]

{ #category : 'accessing' }
AbMockOrchestrationForGroup >> runResult: aString [
	runResult := aString
]
