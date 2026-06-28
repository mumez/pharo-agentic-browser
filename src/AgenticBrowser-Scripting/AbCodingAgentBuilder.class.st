"
I configure which AI coding agent and mode to use for an orchestration step.

I am built via an #agentBy: block in the DSL. Shortcut messages (#claude, #codex, #gemini, etc.)
set the agent command arguments from AbSettings presets. Optional messages (#planMode, #model:)
add further configuration that is applied once the ACP session is established.

Responsibility:
- Hold the agent command arguments (looked up from AbSettings presets by name)
- Optionally hold a mode (e.g. #plan) and a model name override
- Apply mode and model to a topic once its ACP session is established

Collaborators:
- AbTopicOrchestrationBuilder: creates me via #agentBy:
- AbOrchestrationStep: calls #copyForRun (for parallel steps) and #finalizeOnSessionEstablished:
- AbSettings: provides agent argument presets by agent name
- AbTopic: receives agent arguments, mode config, and model config

Public API and Key Messages:
- #claude / #codex / #gemini / #opencode / #copilot / #cursorAgent / #kilo / #kiro - select a preset agent
- #planMode - start the agent in plan mode (where supported)
- #model: aString - override the model name passed to the agent
"
Class {
	#name : 'AbCodingAgentBuilder',
	#superclass : 'AbElementBuilder',
	#instVars : [
		'agentArguments',
		'mode',
		'model'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'privates' }
AbCodingAgentBuilder >> applyModeTo: aTopic [
	| modeOption modeNormalized flatOptions matchingOption |
	self mode ifNil: [ ^ self ].
	modeOption := aTopic session modeConfigOption.
	modeOption ifNil: [
		(AbScriptingError modeNotSupported: ('Mode not supported: {1}' format: { self mode })) signal ].
	modeNormalized := self mode asLowercase.
	flatOptions := self flattenedOptions: modeOption options.
	matchingOption := flatOptions
		detect: [ :opt | ((opt name findTokens: String space) collect: #asLowercase) includes: modeNormalized ]
		ifNone: [
			(AbScriptingError
				noMatchingMode: ('No matching mode option for {1}. Available: {2}' format: { self mode. (flatOptions collect: #name) })
				requestedMode: self mode
				availableOptions: flatOptions) signal ].
	aTopic setConfigOptionId: modeOption id value: matchingOption value
]

{ #category : 'privates' }
AbCodingAgentBuilder >> applyModelTo: aTopic [
	| modelOption modelNormalized flatOptions matchingOption |
	self model ifNil: [ ^ self ].
	modelOption := aTopic session modelConfigOption.
	modelOption ifNil: [
		(AbScriptingError modelNotSupported: ('Model not supported: {1}' format: { self model })) signal ].
	modelNormalized := self model asLowercase.
	flatOptions := self flattenedOptions: modelOption options.
	matchingOption := flatOptions
		detect: [ :opt | opt value asLowercase = modelNormalized ]
		ifNone: [
			(AbScriptingError
				noMatchingModel: ('No matching model option for {1}' format: { self model })
				requestedModel: self model
				availableOptions: flatOptions) signal ].
	aTopic setConfigOptionId: modelOption id value: matchingOption value
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> claude [
	self useAgentArgumentsAt: 'claude-agent-acp'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> codex [
	self useAgentArgumentsAt: 'codex-acp'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> copilot [
	self useAgentArgumentsAt: 'Copilot CLI'
]

{ #category : 'copying' }
AbCodingAgentBuilder >> copyForRun [
	^ (self class new)
		agentArguments: self agentArguments;
		mode: self mode;
		model: self model;
		yourself
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> cursorAgent [
	self useAgentArgumentsAt: 'Cursor CLI'
]

{ #category : 'callbacks' }
AbCodingAgentBuilder >> finalizeOnSessionEstablished: aTopic [
	self applyModeTo: aTopic.
	self applyModelTo: aTopic.
	super finalizeOnSessionEstablished: aTopic
]

{ #category : 'privates' }
AbCodingAgentBuilder >> flattenedOptions: aCollection [
	^ aCollection flatCollect: [ :opt |
		opt isGroup
			ifTrue: [ opt options ]
			ifFalse: [ { opt } ] ]
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> gemini [
	self useAgentArgumentsAt: 'Gemini CLI'
]

{ #category : 'initialization' }
AbCodingAgentBuilder >> initialize [
	super initialize.
	agentArguments := #().
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> kilo [
	self useAgentArgumentsAt: 'Kilo Code'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> kiro [
	self useAgentArgumentsAt: 'Kiro CLI'
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> mode [
	^ mode
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> mode: aModeName [
	mode := aModeName
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> model [
	^ model
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> model: aModelName [
	model := aModelName
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> opencode [
	self useAgentArgumentsAt: 'OpenCode'
]

{ #category : 'actions' }
AbCodingAgentBuilder >> planMode [
	self mode: #plan
]

{ #category : 'actions' }
AbCodingAgentBuilder >> useAgentArgumentsAt: agentName [
	self agentArguments: (AbSettings default agentArgumentsPresets at: agentName)
]
