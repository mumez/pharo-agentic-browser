Class {
	#name : 'AbMockTopicOrchestrationNeverCompletes',
	#superclass : 'AbMockTopicOrchestration',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'building' }
AbMockTopicOrchestrationNeverCompletes >> orchestrationBuilderClass [
	^ AbMockTopicOrchestrationBuilderNeverCompletes
]
