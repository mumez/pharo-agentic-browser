"
I am a mock orchestration that runs indefinitely without ever firing AbOrchestrationEnded.
Used to test timeout behavior in AbOrchestrationGroupParallelStep.
"
Class {
	#name : 'AbMockOrchestrationForGroupNeverCompletes',
	#superclass : 'Object',
	#instVars : [
		'announcer'
	],
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'accessing' }
AbMockOrchestrationForGroupNeverCompletes >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'running' }
AbMockOrchestrationForGroupNeverCompletes >> run [
	"Never fires AbOrchestrationEnded — caller will time out waiting"
]
