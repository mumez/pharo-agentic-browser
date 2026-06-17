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
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testAutoApprovalSettingsAppliedToTopics [
	| orchestration topic |
	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ]
		}
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			topic := ann topic.
			self simulateEndTurnWhenWorkingFor: topic ]
		for: self.

	[
		orchestration run.
		self assert: topic settings aiPermissionWaitTimeoutSeconds equals: 0.
		self assert: topic settings aiPermissionTimeoutOption equals: #allow_once.
		self assert: topic settings exportApprovalWaitTimeoutSeconds equals: 0.
		self assert: topic settings exportApprovalTimeoutOption equals: #allow_once
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationDefaultAgentConfigOverride [
	| orchestration topic |
	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ]
		}
	].
	orchestration defaultAgentConfig: (AbAgentBuilder new codex; yourself).

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			topic := ann topic.
			self simulateEndTurnWhenWorkingFor: topic ]
		for: self.

	[
		orchestration run.
		self assert: topic agentArguments equals: #( 'codex-acp' )
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepInjectsGoalResult [
	| orchestration promptT2 |
	promptT2 := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1'.
				t goal: 'pass all tests' ].
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
				self simulateGoalAchievementWhenWorkingFor: topic resultText: 'Goal file result' ].
			topic title = 'ab-test-T2' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT2 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ]
		]
		for: self.

	[
		orchestration run.
		self assert: promptT2 notNil.
		self assert: (promptT2 includesSubstring: 'Goal file result' )
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepWaitsForGoalAchievedWhenGoalSet [
	| orchestration achievedStatuses |
	achievedStatuses := OrderedCollection new.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1'.
				t goal: 'pass all tests' ]
		}
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic announcer
				when: AbTopicStatusChanged
				do: [ :statusAnn |
					statusAnn status = #goalAchieved ifTrue: [
						achievedStatuses add: statusAnn status ] ]
				for: self.
			self simulateGoalAchievementWhenWorkingFor: topic resultText: 'Done.' ]
		for: self.

	[
		orchestration run.
		self assert: (achievedStatuses includes: #goalAchieved)
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSharedDirectoryPathAppliedToTopics [
	| orchestration sharedPath capturedPaths |
	sharedPath := (AbSettings defaultAgenticBrowserRootDirectory / 'ab-test-orchestration-shared') fullName.
	capturedPaths := OrderedCollection new.

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
	orchestration sharedDirectoryPath: sharedPath.

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			capturedPaths add: ann topic workingDirectoryPath.
			self simulateEndTurnWhenWorkingFor: ann topic ]
		for: self.

	[
		orchestration run.
		self assert: capturedPaths size equals: 2.
		capturedPaths do: [ :each | self assert: each equals: sharedPath ]
	] ensure: [
		self unsubscribeTopicHandlers.
		sharedPath asFileReference exists ifTrue: [
			sharedPath asFileReference deleteAll ] ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testTopicBuilderUsesCustomPrompt [
	| orchestration prompt |
	prompt := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1'.
				t prompt: 'Do the custom thing' ]
		}
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic announcer
				when: AbTopicStatusChanged
				do: [ :statusAnn |
					statusAnn status = #working ifTrue: [
						prompt := topic messages first text.
						topic stateMachine handleEvent: #turnEnded ] ]
				for: self ]
		for: self.

	[
		orchestration run.
		self assert: prompt equals: 'Do the custom thing'
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'private' }
AbTopicOrchestrationTest >> simulateAiResultWhenWorkingFor: aTopic resultText: aString [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :statusAnn |
			statusAnn status = #working ifTrue: [
				aTopic addAiTextChunk: aString.
				aTopic stateMachine handleEvent: #turnEnded ] ]
		for: self
]

{ #category : 'private' }
AbTopicOrchestrationTest >> simulateEndTurnWhenWorkingFor: aTopic [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :statusAnn |
			statusAnn status = #working ifTrue: [
				aTopic stateMachine handleEvent: #turnEnded ] ]
		for: self
]

{ #category : 'private' }
AbTopicOrchestrationTest >> simulateGoalAchievementWhenWorkingFor: aTopic resultText: aString [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :statusAnn |
			statusAnn status = #working ifTrue: [
				| resultFile |
				resultFile := aTopic topicGoal resultFile.
				resultFile parent ensureCreateDirectory.
				resultFile writeStreamDo: [ :s | s nextPutAll: aString ] ] ]
		for: self
]

{ #category : 'private' }
AbTopicOrchestrationTest >> unsubscribeTopicHandlers [
	AbTopicManager activeManager announcer unsubscribe: self.
	AbTopicManager forTest topicsDo: [ :t | t announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testMultiStepOrchestrationInjectsResultAcrossSeqParaSeq [
	| orchestration promptT2 promptT3 promptT4 |
	promptT2 := nil.
	promptT3 := nil.
	promptT4 := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ] }.
		builder para: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ].
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T3' ] }.
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T4' ] }
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				self simulateAiResultWhenWorkingFor: topic resultText: 'Plan output' ].
			topic title = 'ab-test-T2' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT2 := topic messages first text.
							topic addAiTextChunk: 'Implement output'.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ].
			topic title = 'ab-test-T3' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT3 := topic messages first text.
							topic addAiTextChunk: 'Tests output'.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ].
			topic title = 'ab-test-T4' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT4 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ] ]
		for: self.

	[
		orchestration run.
		self assert: (promptT2 includesSubstring: 'Plan output').
		self assert: (promptT3 includesSubstring: 'Plan output').
		self assert: (promptT4 includesSubstring: 'Implement output').
		self assert: (promptT4 includesSubstring: 'Tests output')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepCombinesResultsForNextStep [
	| orchestration promptT3 |
	promptT3 := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder para: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ].
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ] }.
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T3' ] }
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				self simulateAiResultWhenWorkingFor: topic resultText: 'Para result A' ].
			topic title = 'ab-test-T2' ifTrue: [
				self simulateAiResultWhenWorkingFor: topic resultText: 'Para result B' ].
			topic title = 'ab-test-T3' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT3 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ] ]
		for: self.

	[
		orchestration run.
		self assert: (promptT3 includesSubstring: 'Para result A').
		self assert: (promptT3 includesSubstring: 'Para result B')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepInjectsResultFromPriorStep [
	| orchestration promptT2 promptT3 |
	promptT2 := nil.
	promptT3 := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ] }.
		builder para: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ].
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T3' ] }
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				self simulateAiResultWhenWorkingFor: topic resultText: 'Plan result' ].
			topic title = 'ab-test-T2' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT2 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ].
			topic title = 'ab-test-T3' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT3 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ] ]
		for: self.

	[
		orchestration run.
		self assert: (promptT2 includesSubstring: 'Plan result').
		self assert: (promptT3 includesSubstring: 'Plan result')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepInjectsResultFromPriorStep [
	| orchestration promptT2 |
	promptT2 := nil.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ] }.
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ] }
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				self simulateAiResultWhenWorkingFor: topic resultText: 'Step one result' ].
			topic title = 'ab-test-T2' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							promptT2 := topic messages first text.
							topic stateMachine handleEvent: #turnEnded ] ]
					for: self ] ]
		for: self.

	[
		orchestration run.
		self assert: (promptT2 includesSubstring: 'Step one result')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testMultiStepOrchestrationRunsStepsInOrder [
	| orchestration t1Finished t4AddedEarly addedTitles |
	t1Finished := false.
	t4AddedEarly := false.
	addedTitles := OrderedCollection new.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ] }.
		builder para: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T2' ].
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T3' ] }.
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T4' ] }
	].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic parallelTopicsStarted |
			topic := ann topic.
			addedTitles add: topic title.
			topic title = 'ab-test-T1' ifTrue: [
				topic announcer
					when: AbTopicStatusChanged
					do: [ :statusAnn |
						statusAnn status = #working ifTrue: [
							topic stateMachine handleEvent: #turnEnded ].
						statusAnn status = #endTurn ifTrue: [
							t1Finished := true ] ]
					for: self ].
			parallelTopicsStarted := #('ab-test-T2' 'ab-test-T3') includes: topic title.
			parallelTopicsStarted ifTrue: [
				self simulateEndTurnWhenWorkingFor: topic ].
			topic title = 'ab-test-T4' ifTrue: [
				((addedTitles includes: 'ab-test-T2') and: [ addedTitles includes: 'ab-test-T3' ])
					ifFalse: [ t4AddedEarly := true ].
				self simulateEndTurnWhenWorkingFor: topic ] ]
		for: self.

	[
		orchestration run.
		self assert: t1Finished.
		self deny: t4AddedEarly.
		self assert: addedTitles first equals: 'ab-test-T1'.
		self assert: addedTitles last equals: 'ab-test-T4'.
		self assert: addedTitles size equals: 4.
		self assert: (addedTitles includes: 'ab-test-T2').
		self assert: (addedTitles includes: 'ab-test-T3')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepAppliesPlanModeOnConnect [
	| orchestration topic modeSet |
	modeSet := false.

	orchestration := AbTopicOrchestration build: [ :builder |
		builder seq: {
			builder topicBy: [ :t |
				t topicClass: AbMockTopicNoPromptSend.
				t title: 'ab-test-T1' ]
		} with: (builder agentBy: [ :a | a claude; planMode ]) ].

	AbTopicManager activeManager announcer
		when: AbTopicAdded
		do: [ :ann |
			| mockClient result |
			topic := ann topic.
			topic session sessionId: 'session-1'.
			result := MockObject new.
			result on: #configOptions verify: [
				OrderedCollection with: (self modeOptionWithCurrentValue: 'plan') ].
			mockClient := MockObject new.
			mockClient
				on: #setSessionConfigOptionBy:
				with: MockObject any
				verify: [ :aBlock |
					| params |
					params := ACPSetSessionConfigOptionParams buildBy: aBlock.
					self assert: params value equals: 'plan'.
					modeSet := true.
					result ].
			topic session client: mockClient.
			self simulateEndTurnWhenWorkingFor: topic ]
		for: self.

	[
		orchestration run.
		self assert: modeSet.
		self assert: topic currentMode equals: 'plan'
	] ensure: [ self unsubscribeTopicHandlers ]
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
	] ensure: [ self unsubscribeTopicHandlers ]
]
