Extension { #name : 'AgenticBrowser' }

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> scriptBy: aBlock [
	^ AbTopicOrchestration buildBy: aBlock
]

{ #category : '*AgenticBrowser-Scripting' }
AgenticBrowser class >> runBy: aBlock [
	^ (self scriptBy: aBlock) run
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleSingleTopicFileCreation [
	<script>
	| result |
	result := self runBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Create greeting file'.
				t prompt: 'Create a file named hello.txt with the text "Hello, Agentic Browser!" in the current directory. Nothing else.' ]
		} agentBy: [ :a | a claude ] ].
	Transcript crShow: 'Result: ' , result printString
]
