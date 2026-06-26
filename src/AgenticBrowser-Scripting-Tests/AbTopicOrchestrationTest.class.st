Class {
	#name : 'AbTopicOrchestrationTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'private' }
AbTopicOrchestrationTest >> capturePromptOnWorkingFor: aTopic into: aDictionary at: aKey [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :statusAnn |
			statusAnn status = #working ifTrue: [
				| latestHumanMessage |
				latestHumanMessage := aTopic messages reversed
					detect: [ :msg | msg sender = #human ]
					ifNone: [ nil ].
				latestHumanMessage ifNotNil: [
					aDictionary at: aKey put: latestHumanMessage text ] ] ]
		for: self
]

{ #category : 'private' }
AbTopicOrchestrationTest >> mockPlanModeOn: aTopic recordingInto: planModeApplied [
	| mockClient result |
	aTopic session sessionId: 'session-smoke'.
	aTopic session configOptions: (OrderedCollection with: (self modeOptionWithCurrentValue: 'plan')).
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
			planModeApplied at: 1 put: true.
			result ].
	aTopic session client: mockClient
]

{ #category : 'private' }
AbTopicOrchestrationTest >> modeOptionWithCurrentValue: aValue [
	| opt |
	opt := ACPConfigOption new beModeCategory.
	opt rawValues at: 'id' put: 'mode'.
	opt rawValues at: 'currentValue' put: aValue.
	opt rawValues at: 'options' put: { (Dictionary with: 'name' -> 'Plan' with: 'value' -> aValue) }.
	^ opt
]

{ #category : 'private' }
AbTopicOrchestrationTest >> registerSmokeCompletionHandlerFor: aTopic into: completedTitles [
	aTopic announcer
		when: AbTopicStatusChanged
		do: [ :statusAnn |
			(statusAnn status = #endTurn or: [ statusAnn status = #goalAchieved ]) ifTrue: [
				(completedTitles includes: aTopic title) ifFalse: [
					completedTitles add: aTopic title ] ] ]
		for: self
]

{ #category : 'private' }
AbTopicOrchestrationTest >> registerSmokeHandlersFor: aTopic
	prompts: prompts
	completedTitles: completedTitles
	planModeApplied: planModeApplied [

	(self smokePlanningStepTitles includes: aTopic title) ifTrue: [
		self mockPlanModeOn: aTopic recordingInto: planModeApplied ].
	aTopic title = self smokePlanTitle ifTrue: [
		self simulateAiResultWhenWorkingFor: aTopic resultText: 'Plan: feature XXX' ].
	aTopic title = self smokeSpecTitle ifTrue: [
		self capturePromptOnWorkingFor: aTopic into: prompts at: #spec.
		self simulateAiResultWhenWorkingFor: aTopic resultText: 'Spec: feature XXX' ].
	aTopic title = self smokeImplementTitle ifTrue: [
		self capturePromptOnWorkingFor: aTopic into: prompts at: #implement.
		self simulateAiResultWhenWorkingFor: aTopic resultText: 'Implementation done' ].
	aTopic title = self smokeTestsTitle ifTrue: [
		self capturePromptOnWorkingFor: aTopic into: prompts at: #tests.
		self simulateGoalAchievementWhenWorkingFor: aTopic resultText: 'Tests green' ].
	aTopic title = self smokeReviewTitle ifTrue: [
		self capturePromptOnWorkingFor: aTopic into: prompts at: #review.
		self simulateAiResultWhenWorkingFor: aTopic resultText: 'Review OK' ].
	aTopic title = self smokePrTitle ifTrue: [
		self capturePromptOnWorkingFor: aTopic into: prompts at: #pr.
		self simulateEndTurnWhenWorkingFor: aTopic ].
	self registerSmokeCompletionHandlerFor: aTopic into: completedTitles
]

{ #category : 'private' }
AbTopicOrchestrationTest >> scriptingExampleOrchestration [
	| planTitle specTitle implementTitle testsTitle reviewTitle prTitle |
	planTitle := self smokePlanTitle.
	specTitle := self smokeSpecTitle.
	implementTitle := self smokeImplementTitle.
	testsTitle := self smokeTestsTitle.
	reviewTitle := self smokeReviewTitle.
	prTitle := self smokePrTitle.
	^ AbMockTopicOrchestration new buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: planTitle ].
			builder topicBy: [ :t | t title: specTitle ]
		} agentBy: [ :a | a claude; planMode ].
		builder para: {
			builder topicBy: [ :t | t title: implementTitle ].
			builder topicBy: [ :t |
				t title: testsTitle.
				t goal: 'pass all tests' ]
		} agentBy: [ :a | a codex ].
		builder seq: {
			builder topicBy: [ :t | t title: reviewTitle ].
			builder topicBy: [ :t | t title: prTitle ] } agentBy: [ :a | a codex ] ]
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
AbTopicOrchestrationTest >> smokeImplementTitle [
	^ 'ab-test-Implement feature XXX'
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokePlanTitle [
	^ 'ab-test-Create plan of feature XXX'
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokePlanningStepTitles [
	^ Array
		with: self smokePlanTitle
		with: self smokeSpecTitle
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokePrTitle [
	^ 'ab-test-create PR of XXX'
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokeReviewTitle [
	^ 'ab-test-Review implementation of XXX'
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokeSpecTitle [
	^ 'ab-test-Create spec of feature XXX'
]

{ #category : 'private' }
AbTopicOrchestrationTest >> smokeTestsTitle [
	^ 'ab-test-Write tests feature XXX'
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testAutoApprovalSettingsAppliedToTopics [
	| orchestration topic |
	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testCodingAgentBuilderCopyForRunIsIndependent [
	| template copy |
	template := AbCodingAgentBuilder new.
	template codex; planMode.
	copy := template copyForRun.
	self assert: copy ~~ template.
	self assert: copy agentArguments equals: template agentArguments.
	self assert: copy mode equals: template mode.
	self assert: template sessionEstablishedActions isEmpty.
	copy sessionEstablishedActions add: [ :t | t class name ].
	self assert: template sessionEstablishedActions isEmpty
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testMultiStepOrchestrationInjectsResultAcrossSeqParaSeq [
	| orchestration promptT2 promptT3 promptT4 |
	promptT2 := nil.
	promptT3 := nil.
	promptT4 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ] } agentBy: [ :a | a codex ].
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T2' ].
				builder topicBy: [ :t | t title: 'ab-test-T3' ] } agentBy: [ :a | a codex ].
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T4' ] } agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testMultiStepOrchestrationRunsStepsInOrder [
	| orchestration t1Finished t4AddedEarly addedTitles |
	t1Finished := false.
	t4AddedEarly := false.
	addedTitles := OrderedCollection new.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ] } agentBy: [ :a | a codex ].
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T2' ].
				builder topicBy: [ :t | t title: 'ab-test-T3' ] } agentBy: [ :a | a codex ].
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T4' ] } agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testOrchestrationBuilderCreatesSteps [
	| orchestration steps step1 step2 |
	orchestration := AbTopicOrchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ].
			builder topicBy: [ :t | t title: 'T2' ]
		} agentBy: [ :a | a claude; planMode ].
		builder para: {
			builder topicBy: [ :t | t title: 'T3' ]
		} agentBy: [ :a | a codex ].
	].

	self assert: orchestration steps size equals: 2.

	step1 := orchestration steps first.
	self assert: (step1 isKindOf: AbSequentialStep).
	self assert: step1 topicBuilders size equals: 2.
	self assert: step1 topicBuilders first title equals: 'T1'.
	self assert: step1 topicBuilders second title equals: 'T2'.
	self assert: step1 codingAgentBuilder agentArguments equals: #( 'claude-agent-acp' ).

	step2 := orchestration steps second.
	self assert: (step2 isKindOf: AbParallelStep).
	self assert: step2 topicBuilders size equals: 1.
	self assert: step2 topicBuilders first title equals: 'T3'.
	self assert: step2 codingAgentBuilder agentArguments equals: #( 'codex-acp' )
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationBuilderSetsNameViaDSL [
	| orchestration |
	orchestration := AbTopicOrchestration buildBy: [ :builder |
		builder name: 'my-orchestration' ].
	self assert: orchestration name equals: 'my-orchestration'
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationBuilderSetsSettingsViaDSL [
	| orchestration settings |
	settings := AbSettings defaultCopied.
	settings lingerOrchestrationTopicsAfterRun: true.
	orchestration := AbTopicOrchestration buildBy: [ :builder |
		builder settings: settings ].
	self assert: orchestration settings lingerOrchestrationTopicsAfterRun
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationBuilderSetsSharedDirectoryPathViaDSL [
	| orchestration |
	orchestration := AbTopicOrchestration buildBy: [ :builder |
		builder sharedDirectoryPath: '/tmp/test-orchestration' ].
	self assert: orchestration sharedDirectoryPath equals: '/tmp/test-orchestration'
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testOrchestrationFiresEndedAnnouncementOnRunComplete [
	| orchestration endedAnnouncement |
	endedAnnouncement := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ]
			} agentBy: [ :a | a codex ] ].

	orchestration announcer
		when: AbOrchestrationEnded
		do: [ :ann | endedAnnouncement := ann ]
		for: self.

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann | self simulateEndTurnWhenWorkingFor: ann topic ]
		for: self.

	[
		orchestration run.
		self assert: endedAnnouncement notNil.
		self assert: endedAnnouncement orchestration == orchestration
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepAppliesPlanModeOnConnect [
	| orchestration modeSetCount |
	modeSetCount := 0.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a claude; planMode ] ].

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic mockClient result |
			topic := ann topic.
			topic session sessionId: 'session-parallel-plan'.
			topic session configOptions: (OrderedCollection with: (self modeOptionWithCurrentValue: 'plan')).
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
					modeSetCount := modeSetCount + 1.
					result ].
			topic session client: mockClient.
			self simulateEndTurnWhenWorkingFor: topic ]
		for: self.

	[
		orchestration run.
		self assert: modeSetCount equals: 2
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepCombinesResultsForNextStep [
	| orchestration promptT3 |
	promptT3 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ] } agentBy: [ :a | a codex ].
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T3' ] } agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testParallelStepExecution [
	| orchestration ranT1 ranT2 |
	ranT1 := false.
	ranT2 := false.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepInjectsResultFromPriorStep [
	| orchestration promptT2 promptT3 |
	promptT2 := nil.
	promptT3 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ] } agentBy: [ :a | a codex ].
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T2' ].
				builder topicBy: [ :t | t title: 'ab-test-T3' ] } agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testParallelStepRunRaisesTimeoutWhenTopicNeverCompletes [
	| orchestration raisedException |
	orchestration := AbMockTopicOrchestrationNeverCompletes new
		buildBy: [ :builder |
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-never-para' ]
			} agentBy: [ :a | a codex ] ].
	orchestration settings orchestrationStepWaitTimeoutSeconds: 0.
	raisedException := nil.
	[
		[ orchestration run ]
			on: AbOrchestrationStepTimeout
			do: [ :e | raisedException := e ]
	] ensure: [ self unsubscribeTopicHandlers ].
	self assert: raisedException notNil.
	self assert: (raisedException step isKindOf: AbParallelStep)
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testParallelStepTopicsDoNotInjectEachOthersResults [
	"Topics within the same parallel step must NOT see each other's results in their prompts."
	| orchestration prompts |
	prompts := Dictionary new.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder para: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic title = 'ab-test-T1' ifTrue: [
				self capturePromptOnWorkingFor: topic into: prompts at: #t1.
				self simulateAiResultWhenWorkingFor: topic resultText: 'Result from T1' ].
			topic title = 'ab-test-T2' ifTrue: [
				self capturePromptOnWorkingFor: topic into: prompts at: #t2.
				self simulateAiResultWhenWorkingFor: topic resultText: 'Result from T2' ] ]
		for: self.

	[
		orchestration run.
		self deny: ((prompts at: #t1) includesSubstring: 'Result from T2').
		self deny: ((prompts at: #t2) includesSubstring: 'Result from T1')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testRunRemovesTopicsFromManagerEvenOnError [
	| orchestration raisedException topicAdded |
	topicAdded := false.

	orchestration := AbMockTopicOrchestrationNeverCompletes new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-error-cleanup-topic' ]
			} agentBy: [ :a | a codex ] ].
	orchestration settings orchestrationStepWaitTimeoutSeconds: 0.
	raisedException := nil.

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			ann topic title = 'ab-test-error-cleanup-topic' ifTrue: [ topicAdded := true ] ]
		for: self.

	[
		[ orchestration run ]
			on: AbOrchestrationStepTimeout
			do: [ :e | raisedException := e ]
	] ensure: [ self unsubscribeTopicHandlers ].

	self assert: raisedException notNil.
	self assert: topicAdded.
	self assert: (AbTopicManager forTest topics noneSatisfy: [ :t | t title = 'ab-test-error-cleanup-topic' ])
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testScriptingExampleSmoke [
	| orchestration completedTitles prompts planModeApplied planTopic implementTopic reviewTopic |
	completedTitles := OrderedCollection new.
	prompts := Dictionary new.
	planModeApplied := Array with: false.
	planTopic := nil.
	implementTopic := nil.
	reviewTopic := nil.

	orchestration := self scriptingExampleOrchestration.

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			self registerSmokeHandlersFor: ann topic
				prompts: prompts
				completedTitles: completedTitles
				planModeApplied: planModeApplied.
			ann topic title = self smokePlanTitle ifTrue: [ planTopic := ann topic ].
			ann topic title = self smokeImplementTitle ifTrue: [ implementTopic := ann topic ].
			ann topic title = self smokeReviewTitle ifTrue: [ reviewTopic := ann topic ] ]
		for: self.

	[
		orchestration run.
		self assert: completedTitles size equals: 6.
		self assert: (completedTitles includes: self smokePlanTitle).
		self assert: (completedTitles includes: self smokeSpecTitle).
		self assert: (completedTitles includes: self smokeImplementTitle).
		self assert: (completedTitles includes: self smokeTestsTitle).
		self assert: (completedTitles includes: self smokeReviewTitle).
		self assert: (completedTitles includes: self smokePrTitle).
		self assert: planModeApplied first.
		self assert: planTopic notNil.
		self assert: implementTopic notNil.
		self assert: reviewTopic notNil.
		self assert: planTopic agentArguments equals: #( 'claude-agent-acp' ).
		self assert: implementTopic agentArguments equals: #( 'codex-acp' ).
		self assert: reviewTopic agentArguments equals: #( 'codex-acp' ).
		self assert: ((prompts at: #spec) includesSubstring: 'Plan: feature XXX').
		self assert: ((prompts at: #implement) includesSubstring: 'Spec: feature XXX').
		self assert: ((prompts at: #tests) includesSubstring: 'Spec: feature XXX').
		self assert: ((prompts at: #review) includesSubstring: 'Implementation done').
		self assert: ((prompts at: #review) includesSubstring: 'Tests green').
		self assert: ((prompts at: #pr) includesSubstring: 'Review OK')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepAppliesPlanModeOnConnect [
	| orchestration topic modeSet |
	modeSet := false.

	orchestration := AbMockTopicOrchestration new.
	orchestration settings lingerOrchestrationTopicsAfterRun: true.
	orchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'ab-test-T1' ]
		} agentBy: [ :a | a claude; planMode ] ].

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			| mockClient result |
			topic := ann topic.
			topic session sessionId: 'session-1'.
			topic session configOptions: (OrderedCollection with: (self modeOptionWithCurrentValue: 'plan')).
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
AbTopicOrchestrationTest >> testSequentialStepExecutionAndResultInjection [
	| orchestration ranT1 ranT2 promptT2 |
	ranT1 := false.
	ranT2 := false.
	promptT2 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testSequentialStepInjectsGoalResult [
	| orchestration promptT2 |
	promptT2 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t |
					t title: 'ab-test-T1'.
					t goal: 'pass all tests' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testSequentialStepInjectsResultFromPriorStep [
	| orchestration promptT2 |
	promptT2 := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ] } agentBy: [ :a | a codex ].
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T2' ] } agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testSequentialStepInvokesTopicBuilderFinalizeOnSessionEstablished [
	| orchestration sessionEstablishedActionCalled |
	sessionEstablishedActionCalled := false.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t |
					t title: 'ab-test-T1'.
					t sessionEstablishedActions add: [ :topic | sessionEstablishedActionCalled := true ] ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann | self simulateEndTurnWhenWorkingFor: ann topic ]
		for: self.

	[
		orchestration run.
		self assert: sessionEstablishedActionCalled
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepRunRaisesTimeoutWhenTopicNeverCompletes [
	| orchestration raisedException |
	orchestration := AbMockTopicOrchestrationNeverCompletes new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-never-seq' ]
			} agentBy: [ :a | a codex ] ].
	orchestration settings orchestrationStepWaitTimeoutSeconds: 0.
	raisedException := nil.
	[
		[ orchestration run ]
			on: AbOrchestrationStepTimeout
			do: [ :e | raisedException := e ]
	] ensure: [ self unsubscribeTopicHandlers ].
	self assert: raisedException notNil.
	self assert: (raisedException step isKindOf: AbSequentialStep)
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testSequentialStepWaitsForGoalAchievedWhenGoalSet [
	| orchestration achievedStatuses |
	achievedStatuses := OrderedCollection new.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t |
					t title: 'ab-test-T1'.
					t goal: 'pass all tests' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t | t title: 'ab-test-T1' ].
				builder topicBy: [ :t | t title: 'ab-test-T2' ]
			} agentBy: [ :a | a codex ] ].
	orchestration sharedDirectoryPath: sharedPath.

	AbTopicManager forTest announcer
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
AbTopicOrchestrationTest >> testStepBySharedDirectoryPathOverridesOrchestrationPath [
	| orchestration seqStep paraStep defaultStep |
	orchestration := AbTopicOrchestration buildBy: [ :builder |
		builder sharedDirectoryPath: '/tmp/orchestration-path'.
		builder seq: { builder topic } agentBy: [ :a | a codex ] stepBy: [ :s |
			s sharedDirectoryPath: '/tmp/custom-seq' ].
		builder para: { builder topic } agentBy: [ :a | a codex ] stepBy: [ :s |
			s sharedDirectoryPath: '/tmp/custom-para' ].
		builder seq: { builder topic } agentBy: [ :a | a codex ] ].
	seqStep := orchestration steps first.
	paraStep := orchestration steps second.
	defaultStep := orchestration steps third.
	self assert: seqStep sharedDirectoryPath equals: '/tmp/custom-seq'.
	self assert: paraStep sharedDirectoryPath equals: '/tmp/custom-para'.
	self assert: defaultStep sharedDirectoryPath equals: '/tmp/orchestration-path'
]

{ #category : 'tests' }
AbTopicOrchestrationTest >> testTopicBuilderUsesCustomPrompt [
	| orchestration prompt |
	prompt := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t |
					t title: 'ab-test-T1'.
					t prompt: 'Do the custom thing' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
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

{ #category : 'tests' }
AbTopicOrchestrationTest >> testTopicWithGoalUsesSinglePromptContainingGoalInstruction [
	| orchestration sentPrompt |
	sentPrompt := nil.

	orchestration := AbMockTopicOrchestration new
		buildBy: [ :builder |
			builder seq: {
				builder topicBy: [ :t |
					t title: 'ab-test-T1'.
					t prompt: 'Do the custom thing'.
					t goal: 'pass all tests' ]
			} agentBy: [ :a | a codex ] ].

	AbTopicManager forTest announcer
		when: AbTopicAdded
		do: [ :ann |
			| topic |
			topic := ann topic.
			topic announcer
				when: AbTopicStatusChanged
				do: [ :statusAnn |
					statusAnn status = #working ifTrue: [
						| resultFile |
						sentPrompt := topic messages first text.
						resultFile := topic topicGoal resultFile.
						resultFile parent ensureCreateDirectory.
						resultFile writeStreamDo: [ :s | s nextPutAll: 'Done.' ] ] ]
				for: self ]
		for: self.

	[
		orchestration run.
		self assert: sentPrompt notNil.
		self assert: (sentPrompt includesSubstring: 'Do the custom thing').
		self assert: (sentPrompt includesSubstring: 'Goal has been set: pass all tests')
	] ensure: [ self unsubscribeTopicHandlers ]
]

{ #category : 'private' }
AbTopicOrchestrationTest >> unsubscribeTopicHandlers [
	AbTopicManager forTest announcer unsubscribe: self.
	AbTopicManager forTest topicsDo: [ :t | t announcer unsubscribe: self ]
]
