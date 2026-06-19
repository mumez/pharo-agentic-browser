Class {
	#name : 'AbTopicBuilderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'private' }
AbTopicBuilderTest >> codexAgentConfig [

	^ AbCodingAgentBuilder new codex; yourself
]

{ #category : 'tests' }
AbTopicBuilderTest >> testBuildByBlockSetsAttributes [

	| builder |
	builder := AbTopicBuilder new buildBy: [ :t |
		t title: 'Configured title'.
		t goal: 'pass all tests'.
		t prompt: 'Start here'.
		t topicClass: AbMockTopicNoPromptSend ].
	self assert: builder title equals: 'Configured title'.
	self assert: builder goal equals: 'pass all tests'.
	self assert: builder prompt equals: 'Start here'.
	self assert: builder topicClass equals: AbMockTopicNoPromptSend
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithDoesNotCreateTopicGoalWhenGoalNotSet [

	| builder topic |
	builder := AbTopicBuilder new title: 'ab-test-no-goal'.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: (topic instVarNamed: #topicGoal) isNil
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithLeavesDefaultTitleWhenTitleNotSet [

	| builder topic |
	builder := AbTopicBuilder new.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: topic title equals: 'Untitled'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithSetsAgentArguments [

	| builder topic |
	builder := AbTopicBuilder new title: 'ab-test-agent'.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: topic agentArguments equals: #( 'codex-acp' )
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithSetsGoalDescription [

	| builder topic |
	builder := AbTopicBuilder new.
	builder title: 'ab-test-goal'.
	builder goal: 'pass all tests'.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: topic topicGoal description equals: 'pass all tests'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithSetsTitle [

	| builder topic |
	builder := AbTopicBuilder new title: 'ab-test-title'.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: topic title equals: 'ab-test-title'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithUsesCustomTopicClass [

	| builder topic |
	builder := AbTopicBuilder new.
	builder title: 'ab-test-custom-class'.
	builder topicClass: AbMockTopicNoPromptSend.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: (topic isKindOf: AbMockTopicNoPromptSend)
]

{ #category : 'tests' }
AbTopicBuilderTest >> testInstantiateWithUsesDefaultTopicClass [

	| builder topic |
	builder := AbTopicBuilder new title: 'ab-test-default-class'.
	topic := builder instantiateWith: self codexAgentConfig.
	self assert: (topic isKindOf: AbTopic)
]
