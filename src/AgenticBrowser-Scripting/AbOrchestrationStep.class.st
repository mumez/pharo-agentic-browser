Class {
	#name : 'AbOrchestrationStep',
	#superclass : 'Object',
	#instVars : [
		'orchestration',
		'topicBuilders',
		'agentConfig',
		'sharedDirectoryPath'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbOrchestrationStep >> orchestration [
	^ orchestration
]

{ #category : 'accessing' }
AbOrchestrationStep >> orchestration: anOrchestration [
	orchestration := anOrchestration
]

{ #category : 'accessing' }
AbOrchestrationStep >> topicBuilders [
	^ topicBuilders
]

{ #category : 'accessing' }
AbOrchestrationStep >> topicBuilders: aCollection [
	topicBuilders := aCollection
]

{ #category : 'accessing' }
AbOrchestrationStep >> agentConfig [
	^ agentConfig
]

{ #category : 'accessing' }
AbOrchestrationStep >> agentConfig: anAgentConfig [
	agentConfig := anAgentConfig
]

{ #category : 'accessing' }
AbOrchestrationStep >> sharedDirectoryPath [
	^ sharedDirectoryPath
]

{ #category : 'accessing' }
AbOrchestrationStep >> sharedDirectoryPath: aString [
	sharedDirectoryPath := aString
]

{ #category : 'accessing' }
AbOrchestrationStep >> activeAgentConfig [
	^ agentConfig ifNil: [ orchestration defaultAgentConfig ]
]

{ #category : 'running' }
AbOrchestrationStep >> run [
	self subclassResponsibility
]
