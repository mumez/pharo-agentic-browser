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
	self assert: group nodes size equals: 1.
	self assert: (group nodes first isKindOf: AbOrchestrationGroupParaNode)
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testGroupBuildByCreatesSeqNode [
	| o1 o2 group |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	group := AbOrchestrationGroup buildBy: [ :builder |
		builder seq: (OrderedCollection with: o1 with: o2) ].
	self assert: group nodes size equals: 1.
	self assert: (group nodes first isKindOf: AbOrchestrationGroupSeqNode)
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
AbOrchestrationGroupTest >> testOrchestrationByCreatesOrchestration [
	| group |
	group := AbOrchestrationGroup buildBy: [ :builder |
		| o |
		o := builder orchestrationBy: [ :b |
			b name: 'test-orchestration' ].
		self assert: (o isKindOf: AbTopicOrchestration).
		self assert: o name equals: 'test-orchestration'.
		builder seq: (OrderedCollection with: o) ].
	self assert: group nodes size equals: 1
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
	self assert: innerGroup nodes size equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testParaNodeRunsItemsConcurrently [
	| o1 o2 node |
	o1 := AbMockOrchestrationForGroup withResult: 'r1'.
	o1 runDelay: 50.
	o2 := AbMockOrchestrationForGroup withResult: 'r2'.
	o2 runDelay: 50.
	node := AbOrchestrationGroupParaNode new
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
	node := AbOrchestrationGroupParaNode new
		items: (OrderedCollection with: o1 with: o2);
		yourself.
	node run.
	self assert: o1 runCount equals: 1.
	self assert: o2 runCount equals: 1
]

{ #category : 'tests' }
AbOrchestrationGroupTest >> testSeqNodeReturnsLastItemResult [
	| node result |
	node := AbOrchestrationGroupSeqNode new
		items: (OrderedCollection
			with: (AbMockOrchestrationForGroup withResult: 'first')
			with: (AbMockOrchestrationForGroup withResult: 'last'));
		yourself.
	result := node run.
	self assert: result equals: 'last'
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

	node := AbOrchestrationGroupSeqNode new
		items: (OrderedCollection with: o1 with: o2 with: o3);
		yourself.
	node run.

	self assert: runOrder asArray equals: #(1 2 3)
]
