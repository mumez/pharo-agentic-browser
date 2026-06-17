Class {
	#name : 'AbTopicOrchestrationTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationBuilderCreatesSteps [
	| orchestration steps step1 step2 |
	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ].
			builder topicBy: [ :t | t title: 'T2' ]
		} with: (builder agentBy: [ :a | a claude; planMode ]).
		builder para: {
			builder topicBy: [ :t | t title: 'T3' ]
		} with: builder agent codex.
	].

	self assert: orchestration steps size equals: 2.
	
	step1 := orchestration steps first.
	self assert: (step1 isKindOf: AbSequentialStep).
	self assert: step1 topicBuilders size equals: 2.
	self assert: step1 topicBuilders first title equals: 'T1'.
	self assert: step1 topicBuilders second title equals: 'T2'.
	self assert: step1 agentConfig arguments equals: #( 'claude-agent-acp' ).
	
	step2 := orchestration steps second.
	self assert: (step2 isKindOf: AbParallelStep).
	self assert: step2 topicBuilders size equals: 1.
	self assert: step2 topicBuilders first title equals: 'T3'.
	self assert: step2 agentConfig arguments equals: #( 'codex-acp' )
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testDefaultAgentConfigFallback [
	| orchestration step |
	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ]
		}
	].

	step := orchestration steps first.
	self assert: step agentConfig isNil.
	self assert: step activeAgentConfig notNil.
	self assert: step activeAgentConfig arguments equals: orchestration defaultAgentConfig arguments
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepExecutionAndResultInjection [
	| orchestration ranT1 ranT2 promptT2 |
	ranT1 := false.
	ranT2 := false.
	promptT2 := nil.
	
	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t | 
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ].
			builder topicBy: [ :t | 
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ]
		}
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				ranT1 := true.
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							topic addAiTextChunk: 'Result from T1'.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self.
			].
			topic title = 'ab-test-T2' ifTrue: [
				ranT2 := true.
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT2 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self.
			]
		]
		for: self.

	[
		orchestration run.
		self assert: ranT1.
		self assert: ranT2.
		self assert: (promptT2 includesSubstring: 'ab-test-T2').
		self assert: (promptT2 includesSubstring: 'Result from T1')
	] ensure: [
		AbTopicManager activeManager announcer unsubscribe: self.
		AbTopicManager forTest topicsDo: [ :t | t announcer unsubscribe: self ]
	]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepExecution [
	| orchestration ranT1 ranT2 |
	ranT1 := false.
	ranT2 := false.
	
	orchestration := AbTopicOrchestration build: [ :builder |
		builder para: {
			builder topicBy: [ :t | 
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ].
			builder topicBy: [ :t | 
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ]
		}
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				ranT1 := true.
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self.
			].
			topic title = 'ab-test-T2' ifTrue: [
				ranT2 := true.
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self.
			]
		]
		for: self.

	[
		orchestration run.
		self assert: ranT1.
		self assert: ranT2.
	] ensure: [
		AbTopicManager activeManager announcer unsubscribe: self.
		AbTopicManager forTest topicsDo: [ :t | t announcer unsubscribe: self ]
	]
]
