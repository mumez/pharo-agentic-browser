Class {
	#name : 'AbCodingAgentBuilderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testClaudeSetsArguments [

	| builder |
	builder := AbCodingAgentBuilder new claude.
	self assert: builder agentArguments equals: #( 'claude-agent-acp' )
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testCodexSetsArguments [

	| builder |
	builder := AbCodingAgentBuilder new codex.
	self assert: builder agentArguments equals: #( 'codex-acp' )
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testBuildByBlock [

	| builder |
	builder := AbCodingAgentBuilder new buildBy: [ :a | a gemini ].
	self assert: builder agentArguments equals: #( 'gemini' '--acp' )
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testPlanModeUsesModeConfigOptionIdWhenPresent [

	| builder topic modeOption called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbCodingAgentBuilder new planMode.
	modeOption := ACPConfigOption new beModeCategory.
	modeOption rawValues at: 'id' put: 'agent-mode'.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modeConfigOption verify: [ modeOption ].
		session ].
	topic
		on: #setConfigOptionId:value:
		verify: [ :anId :aValue |
			called := true.
			configId := anId.
			configValue := aValue ].
	builder onConnected: topic.
	self assert: called.
	self assert: configId equals: 'agent-mode'.
	self assert: configValue equals: 'plan'
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testPlanModeUsesDefaultModeIdWhenOptionMissing [

	| builder topic called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbCodingAgentBuilder new planMode.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modeConfigOption verify: [ nil ].
		session ].
	topic
		on: #setConfigOptionId:value:
		verify: [ :anId :aValue |
			called := true.
			configId := anId.
			configValue := aValue ].
	builder onConnected: topic.
	self assert: called.
	self assert: configId equals: 'mode'.
	self assert: configValue equals: 'plan'
]
