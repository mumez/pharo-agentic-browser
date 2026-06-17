Class {
	#name : 'AbAgentBuilderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Scripting-Tests',
	#package : 'AgenticBrowser-Scripting-Tests'
}

{ #category : 'tests' }
AbAgentBuilderTest >> testClaudeSetsArguments [

	| builder |
	builder := AbAgentBuilder new claude.
	self assert: builder arguments equals: #( 'claude-agent-acp' )
]

{ #category : 'tests' }
AbAgentBuilderTest >> testCodexSetsArguments [

	| builder |
	builder := AbAgentBuilder new codex.
	self assert: builder arguments equals: #( 'codex-acp' )
]

{ #category : 'tests' }
AbAgentBuilderTest >> testConfigureBlock [

	| builder |
	builder := AbAgentBuilder new configure: [ :a | a gemini ].
	self assert: builder arguments equals: #( 'gemini' '--acp' )
]

{ #category : 'tests' }
AbAgentBuilderTest >> testPlanModeUsesModeConfigOptionIdWhenPresent [

	| builder topic modeOption called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbAgentBuilder new planMode.
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
	builder postConnectActions do: [ :action | action value: topic ].
	self assert: called.
	self assert: configId equals: 'agent-mode'.
	self assert: configValue equals: 'plan'
]

{ #category : 'tests' }
AbAgentBuilderTest >> testPlanModeUsesDefaultModeIdWhenOptionMissing [

	| builder topic called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbAgentBuilder new planMode.
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
	builder postConnectActions do: [ :action | action value: topic ].
	self assert: called.
	self assert: configId equals: 'mode'.
	self assert: configValue equals: 'plan'
]
