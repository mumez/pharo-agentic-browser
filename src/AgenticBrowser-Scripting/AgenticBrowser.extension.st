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
AgenticBrowser class >> exampleSingleTopic [
	<script>
	| orchestrationScript |
	orchestrationScript :=  self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ] ].
	{orchestrationScript. orchestrationScript result} inspect.
]
