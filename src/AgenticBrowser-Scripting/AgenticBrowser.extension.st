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
	[orchestrationScript run.
	{orchestrationScript. orchestrationScript result} inspect] fork.
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
	[orchestrationScript run.
	{orchestrationScript. orchestrationScript result} inspect] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleParallelTopics [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder para: {
			builder topicBy: [ :t |
				t title: 'List Pharo features'.
				t prompt: 'List 3 Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'List Pharo tools'.
				t prompt: 'List 3 Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	{orchestrationScript. orchestrationScript result} inspect] fork.
]

{ #category : '*AgenticBrowser-Scripting-examples-scripting' }
AgenticBrowser class >> exampleMultipleSteps [
	<script>
	| orchestrationScript |
	orchestrationScript := self scriptBy: [ :builder |
		builder para: {
			builder topicBy: [ :t |
				t title: 'Research Pharo language'.
				t prompt: 'List 3 key Pharo Smalltalk language features in one sentence each. Reply with only the list.' ].
			builder topicBy: [ :t |
				t title: 'Research Pharo tools'.
				t prompt: 'List 3 key Pharo Smalltalk development tools in one sentence each. Reply with only the list.' ]
		} agentBy: [ :a | a claude ].
		builder seq: {
			builder topicBy: [ :t |
				t title: 'Write Pharo overview'.
				t prompt: 'Write a short overview paragraph of Pharo Smalltalk based on the research results above.' ]
		} agentBy: [ :a | a claude ] ].
	[orchestrationScript run.
	{orchestrationScript. orchestrationScript result} inspect] fork.
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
	[orchestrationScript run.
	{orchestrationScript. orchestrationScript result} inspect] fork.
]
