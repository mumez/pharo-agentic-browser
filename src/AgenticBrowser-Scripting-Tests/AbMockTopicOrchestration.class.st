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

{ #category : 'accessing' }
AbMockTopicOrchestration >> topicManager [
	^ AbTopicManager forTest
]
