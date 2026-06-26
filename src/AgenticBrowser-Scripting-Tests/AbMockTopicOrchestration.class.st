Class {
	#name : 'AbMockTopicOrchestration',
	#superclass : 'AbTopicOrchestration',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'accessing' }
AbMockTopicOrchestration >> name [
	^ 'ab-test-orchestration'
]

{ #category : 'building' }
AbMockTopicOrchestration >> orchestrationBuilderClass [
	^ AbMockTopicOrchestrationBuilder
]

{ #category : 'accessing' }
AbMockTopicOrchestration >> topicManager [
	^ AbTopicManager forTest
]
