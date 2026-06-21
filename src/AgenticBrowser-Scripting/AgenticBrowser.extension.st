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

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleSequentialTopics [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'Summarize Pharo features'.
				t prompt: 'Summarize the feature list from the previous step in one sentence. Reply with only the summary.' ]
		} agentBy: [ :a | a claude ] ].
	{orchestrationScript. orchestrationScript result} inspect.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleGoalDrivenTopic [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Write Pharo summary'.
				t prompt: 'Write a one-sentence summary of what Pharo Smalltalk is.'.
				t goal: 'summary written to goal file' ]
		} agentBy: [ :a | a claude ] ].
	{orchestrationScript. orchestrationScript result} inspect.
]
