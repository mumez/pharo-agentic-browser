Class {
	#name : 'AbMockTopicBuilderNeverCompletes',
	#superclass : 'AbMockTopicBuilder',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'factory' }
AbMockTopicBuilderNeverCompletes >> createTopic [
	^ AbMockTopicNeverCompletes new
]
