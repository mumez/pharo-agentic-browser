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
AbCodingAgentBuilderTest >> testPlanModeResolvesOptionValueByName [

	| builder topic modeOption called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbCodingAgentBuilder new planMode.
	modeOption := ACPConfigOption new beModeCategory.
	modeOption rawValues at: 'id' put: 'agent-mode'.
	modeOption rawValues at: 'options' put: { (Dictionary with: 'name' -> 'Plan' with: 'value' -> 'plan-value') }.
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
	builder finalizeOnSessionEstablished: topic.
	self assert: called.
	self assert: configId equals: 'agent-mode'.
	self assert: configValue equals: 'plan-value'
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testPlanModeRaisesErrorWhenModeConfigOptionNil [

	| builder topic |
	builder := AbCodingAgentBuilder new planMode.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modeConfigOption verify: [ nil ].
		session ].
	self
		should: [ builder finalizeOnSessionEstablished: topic ]
		raise: AbScriptingError
		withExceptionDo: [ :e | self assert: e kind equals: #modeNotSupported ]
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testPlanModeRaisesErrorWhenNoMatchingOptionFound [

	| builder topic modeOption |
	builder := AbCodingAgentBuilder new planMode.
	modeOption := ACPConfigOption new beModeCategory.
	modeOption rawValues at: 'id' put: 'agent-mode'.
	modeOption rawValues at: 'options' put: { (Dictionary with: 'name' -> 'Normal' with: 'value' -> 'normal') }.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modeConfigOption verify: [ modeOption ].
		session ].
	self
		should: [ builder finalizeOnSessionEstablished: topic ]
		raise: AbScriptingError
		withExceptionDo: [ :e |
			self assert: e kind equals: #noMatchingMode.
			self assert: (e dataAt: #requestedMode) equals: #plan.
			self assert: (e dataAt: #availableOptions) size equals: 1.
			self assert: (e dataAt: #availableOptions) first name equals: 'Normal' ]
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testModelSetsModelName [

	| builder |
	builder := AbCodingAgentBuilder new model: 'claude-opus-4-5'.
	self assert: builder model equals: 'claude-opus-4-5'
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testModelUsesModelConfigOptionIdWhenPresent [

	| builder topic modelOption called configId configValue |
	called := false.
	configId := nil.
	configValue := nil.
	builder := AbCodingAgentBuilder new model: 'claude-opus-4-5'.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'id' put: 'agent-model'.
	modelOption rawValues at: 'options' put: { (Dictionary with: 'name' -> 'Claude Opus' with: 'value' -> 'claude-opus-4-5') }.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modelConfigOption verify: [ modelOption ].
		session ].
	topic
		on: #setConfigOptionId:value:
		verify: [ :anId :aValue |
			called := true.
			configId := anId.
			configValue := aValue ].
	builder finalizeOnSessionEstablished: topic.
	self assert: called.
	self assert: configId equals: 'agent-model'.
	self assert: configValue equals: 'claude-opus-4-5'
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testModelRaisesErrorWhenNoMatchingModelFound [

	| builder topic modelOption |
	builder := AbCodingAgentBuilder new model: 'unknown-model'.
	modelOption := ACPConfigOption new beModelCategory.
	modelOption rawValues at: 'id' put: 'agent-model'.
	modelOption rawValues at: 'options' put: { (Dictionary with: 'name' -> 'Claude Opus' with: 'value' -> 'claude-opus-4-5') }.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modelConfigOption verify: [ modelOption ].
		session ].
	self
		should: [ builder finalizeOnSessionEstablished: topic ]
		raise: AbScriptingError
		withExceptionDo: [ :e |
			self assert: e kind equals: #noMatchingModel.
			self assert: (e dataAt: #requestedModel) equals: 'unknown-model'.
			self assert: (e dataAt: #availableOptions) first value equals: 'claude-opus-4-5' ]
]

{ #category : 'tests' }
AbCodingAgentBuilderTest >> testModelRaisesErrorWhenModelConfigOptionNil [

	| builder topic |
	builder := AbCodingAgentBuilder new model: 'claude-opus-4-5'.
	topic := MockObject new.
	topic on: #session verify: [
		| session |
		session := MockObject new.
		session on: #modelConfigOption verify: [ nil ].
		session ].
	self
		should: [ builder finalizeOnSessionEstablished: topic ]
		raise: AbScriptingError
		withExceptionDo: [ :e | self assert: e kind equals: #modelNotSupported ]
]
