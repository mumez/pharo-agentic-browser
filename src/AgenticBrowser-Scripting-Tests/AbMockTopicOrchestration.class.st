Class {
	#name : 'AbMockTopicOrchestration',
	#superclass : 'AbTopicOrchestration',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'building' }
AbMockTopicOrchestration >> orchestrationBuilderClass [
	^ AbMockTopicOrchestrationBuilder
]

{ #category : 'defaults' }
AbMockTopicOrchestration >> defaultDirectoryNamePrefix [
	^ 'ab-test-orchestration-'
]

{ #category : 'accessing' }
AbMockTopicOrchestration >> topicManager [
	^ AbTopicManager forTest
]
