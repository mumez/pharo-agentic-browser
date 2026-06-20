Class {
	#name : 'AbTopicBuilderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbTopicBuilderTest >> testBuildByBlockSetsAttributes [

	| builder |
	builder := AbTopicBuilder new buildBy: [ :t |
		t title: 'Configured title'.
		t goal: 'pass all tests'.
		t prompt: 'Start here' ].
	self assert: builder title equals: 'Configured title'.
	self assert: builder goal equals: 'pass all tests'.
	self assert: builder prompt equals: 'Start here'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testTopicGoalNotCreatedWhenGoalNotSet [

	| builder |
	builder := AbTopicBuilder new title: 'ab-test-no-goal'.
	self assert: (builder topic instVarNamed: #topicGoal) isNil
]

{ #category : 'tests' }
AbTopicBuilderTest >> testTopicHasDefaultTitleWhenNotSet [

	| builder |
	builder := AbTopicBuilder new.
	self assert: builder topic title equals: 'Untitled'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testTopicTitleSetViaBuilder [

	| builder |
	builder := AbTopicBuilder new title: 'ab-test-title'.
	self assert: builder topic title equals: 'ab-test-title'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testTopicGoalSetViaBuilder [

	| builder |
	builder := AbTopicBuilder new.
	builder title: 'ab-test-goal'.
	builder goal: 'pass all tests'.
	self assert: builder goal equals: 'pass all tests'.
	self assert: (builder topic instVarNamed: #topicGoal) isNil
]

{ #category : 'tests' }
AbTopicBuilderTest >> testOnConnectedAppliesGoalDescriptionToTopic [

	| builder called value topic |
	called := false.
	value := nil.
	builder := AbTopicBuilder new.
	builder goal: 'pass all tests'.
	topic := MockObject new.
	topic
		on: #goalDescription:
		verify: [ :aString |
			called := true.
			value := aString ].
	builder onConnected: topic.
	self assert: called.
	self assert: value equals: 'pass all tests'
]

{ #category : 'tests' }
AbTopicBuilderTest >> testMockTopicBuilderCreatesMockTopic [

	| builder |
	builder := AbMockTopicBuilder new.
	self assert: (builder topic isKindOf: AbMockTopicNoPromptSend)
]
