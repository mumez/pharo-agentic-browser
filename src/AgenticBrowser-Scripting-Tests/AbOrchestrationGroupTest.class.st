Class {
	#name : 'AbOrchestrationGroupTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupBuildByCreatesParaNode [
	| o1 o2 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2) ].
	self assert: group steps size equals: 1.
	self assert: (group steps first isKindOf: AbOrchestrationGroupParallelStep)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupBuildByCreatesSeqNode [
	| o1 o2 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1 with: o2) ].
	self assert: group steps size equals: 1.
	self assert: (group steps first isKindOf: AbOrchestrationGroupSequentialStep)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupFiresOrchestrationEndedOnCompletion [
	| group ended o1 |
	ended := false.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1) ].
	group announcer
		when: AbOrchestrationEnded
		do: [ :ann | ended := true ]
		for: self.
	group run.
	self assert: ended
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupRunExecutesAllNodes [
	| o1 o2 o3 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2).
		builder seq: (OrderedCollection with: o3) ].
	group run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1.
	self assert: o3 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupRunNodesInOrderParaThenSeq [
	| o1 o2 o3 paraFinished seqStarted group |
	paraFinished := false.
	seqStarted := false.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	o1 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o2 announcer when: AbOrchestrationEnded do: [ paraFinished := true ] for: self.
	o3 announcer when: AbOrchestrationEnded do: [ seqStarted := paraFinished ] for: self.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder para: (OrderedCollection with: o1 with: o2).
		builder seq: (OrderedCollection with: o3) ].
	group run.
	self assert: seqStarted
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSingleTopicByAgentByCreatesOrchestrationWithOneTopic [
	| group orch |
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder
			singleTopicBy: [ :t | t prompt: 'Write summary' ]
			agentBy: [ :a | ] ].
	self assert: group steps size equals: 1.
	self assert: (group steps first isKindOf: AbOrchestrationGroupSequentialStep).
	orch := group steps first items first.
	self assert: (orch isKindOf: AbTopicOrchestration).
	self assert: orch steps size equals: 1.
	self assert: (orch steps first isKindOf: AbOrchestrationSequentialStep).
	self assert: orch steps first topicBuilders size equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testOrchestrationByCreatesOrchestration [
	| group |
	group := AbOrchestrationGroup buildBy: [ :builder |
		| o |
		o := builder orchestrationBy: [ :b |
			b name: 'test-orchestration' ].
		self assert: (o isKindOf: AbTopicOrchestration).
		self assert: o name equals: 'test-orchestration'.
		builder seq: (OrderedCollection with: o) ].
	self assert: group steps size equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testOrchestrationGroupByCreatesNestedGroup [
	| outerGroup innerGroup |
	outerGroup := AbOrchestrationGroup buildBy: [ :builder |
		| inner |
		inner := builder orchestrationGroupBy: [ :b |
			| o |
			o := AbMockOrchestrationForGroup withResult: 'r'.
			b seq: (OrderedCollection with: o) ].
		innerGroup := inner.
		builder seq: (OrderedCollection with: inner) ].
	self assert: innerGroup notNil.
	self assert: (innerGroup isKindOf: AbOrchestrationGroup).
	outerGroup run.
	"inner group ran"
	self assert: innerGroup steps size equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaStepRaisesTimeoutWhenItemNeverCompletes [
	| group node raised |
	group := AbOrchestrationGroup new.
	group settings orchestrationGroupItemWaitTimeoutSeconds: 0.
	node := AbOrchestrationGroupParallelStep new
		orchestration: group;
		items: (OrderedCollection with: AbMockOrchestrationForGroupNeverCompletes new);
		yourself.
	raised := nil.
	[ node run ] on: AbOrchestrationStepTimeout do: [ :e | raised := e ].
	self assert: raised notNil
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaNodeRunsItemsConcurrently [
	| o1 o2 node |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 runDelay: 50.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 runDelay: 50.
	node := AbOrchestrationGroupParallelStep new
		items: (OrderedCollection with: o1 with: o2);
		yourself.
	node run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaNodeWaitsForAllItems [
	| o1 o2 node |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 runDelay: 30.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 runDelay: 10.
	node := AbOrchestrationGroupParallelStep new
		items: (OrderedCollection with: o1 with: o2);
		yourself.
	node run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSeqNodeReturnsLastItemResult [
	| node result |
	node := AbOrchestrationGroupSequentialStep new
		items: (OrderedCollection
			with: (AbMockOrchestrationForGroup withResult: 'first')
			with: (AbMockOrchestrationForGroup withResult: 'last'));
		yourself.
	result := node run.
	self assert: result equals: 'last'
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSharedDirectoryPathAppliedToItemsOnRun [
	| group path o1 o2 |
	path := '/tmp/ab-test-group-shared'.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder sharedDirectoryPath: path.
		builder seq: (OrderedCollection with: o1 with: o2) ].
	group run.
	self assert: o1 sharedDirectoryPath equals: path.
	self assert: o2 sharedDirectoryPath equals: path
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSharedDirectoryPathPropagatesIntoNestedGroup [
	| outerGroup path o1 o2 |
	path := '/tmp/ab-test-nested-group-shared'.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	outerGroup := AbOrchestrationGroup buildBy: [ :builder |
		| innerGroup |
		innerGroup := AbOrchestrationGroup buildBy: [ :b |
			b seq: (OrderedCollection with: o1 with: o2) ].
		builder sharedDirectoryPath: path.
		builder seq: (OrderedCollection with: innerGroup) ].
	outerGroup run.
	self assert: o1 sharedDirectoryPath equals: path.
	self assert: o2 sharedDirectoryPath equals: path
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSharedDirectoryPathNotAppliedWhenNotSet [
	| group o1 |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1) ].
	group run.
	self assert: o1 sharedDirectoryPath isNil
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupStepResetForRerunClearsResultsAndItems [
	| step orch |
	orch := AbTopicOrchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	orch previousResult: 'stale-previous'.
	orch steps first stepResult: 'stale-step-result'.
	step := AbOrchestrationGroupSequentialStep new
		items: (OrderedCollection with: orch);
		stepResult: 'stale-group-step-result';
		previousStepResult: 'stale-group-previous-step-result';
		yourself.
	step resetForRerun.
	self assert: step stepResult isNil.
	self assert: step previousStepResult isNil.
	self assert: orch previousResult isNil.
	self assert: orch steps first stepResult isNil
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupResetForRerunRecursesIntoNestedGroup [
	| innerGroup outerGroup orch |
	orch := AbTopicOrchestration buildBy: [ :builder |
		builder seq: {
			builder topicBy: [ :t | t title: 'T1' ]
		} agentBy: [ :a | a codex ] ].
	orch steps first stepResult: 'stale-inner-result'.
	innerGroup := AbOrchestrationGroup buildBy: [ :b |
		b seq: (OrderedCollection with: orch) ].
	outerGroup := AbOrchestrationGroup buildBy: [ :b |
		b seq: (OrderedCollection with: innerGroup) ].
	outerGroup previousResult: 'stale-outer-previous'.
	outerGroup resetForRerun.
	self assert: outerGroup previousResult isNil.
	self assert: orch steps first stepResult isNil
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSeqNodeRunsItemsInOrder [
	| runOrder o1 o2 o3 node |
	runOrder := OrderedCollection new.
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 announcer when: AbOrchestrationEnded do: [ runOrder add: 1 ] for: self.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 announcer when: AbOrchestrationEnded do: [ runOrder add: 2 ] for: self.
	o3 := AbMockOrchestrationForGroup withResult: 'r3'.
	o3 announcer when: AbOrchestrationEnded do: [ runOrder add: 3 ] for: self.

	node := AbOrchestrationGroupSequentialStep new
		items: (OrderedCollection with: o1 with: o2 with: o3);
		yourself.
	node run.

	self assert: runOrder asArray equals: #(1 2 3)
]
