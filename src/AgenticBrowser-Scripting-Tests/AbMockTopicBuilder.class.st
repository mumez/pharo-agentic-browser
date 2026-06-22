Class {
	#name : 'AbMockTopicBuilder',
	#superclass : 'AbTopicBuilder',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'factory' }
AbMockTopicBuilder >> createTopic [
	^ AbMockTopicNoPromptSend new
]
