Class {
	#name : 'AbOrchestrationGroupTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

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
AbOrchestrationGroupTest >> testParaNodeRunsItemsConcurrently [
	| startTimes o1 o2 node |
	startTimes := OrderedCollection new.
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
