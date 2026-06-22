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

{ #category : 'initialization' }
AbCodingAgentBuilder >> initialize [
	super initialize.
	agentArguments := #().
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'actions' }
AbCodingAgentBuilder >> useAgentArgumentsAt: agentName [
	self agentArguments: (AbSettings default agentArgumentsPresets at: agentName)
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
AbCodingAgentBuilder >> gemini [
	self useAgentArgumentsAt: 'Gemini CLI'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> opencode [
	self useAgentArgumentsAt: 'OpenCode'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> copilot [
	self useAgentArgumentsAt: 'Copilot CLI'
]

{ #category : 'shortcuts' }
AbCodingAgentBuilder >> cursorAgent [
	self useAgentArgumentsAt: 'Cursor CLI'
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

{ #category : 'actions' }
AbCodingAgentBuilder >> planMode [
	self mode: #plan
]

{ #category : 'copying' }
AbCodingAgentBuilder >> copyForRun [
	^ (self class new)
		agentArguments: self agentArguments;
		mode: self mode;
		model: self model;
		yourself
]

{ #category : 'privates' }
AbCodingAgentBuilder >> applyModeTo: aTopic [
	| modeOption |
	self mode ifNil: [ ^ self ].
	modeOption := aTopic session modeConfigOption.
	modeOption
		ifNotNil: [ aTopic setConfigOptionId: modeOption id value: self mode ]
		ifNil: [ aTopic setConfigOptionId: 'mode' value: self mode ]
]

{ #category : 'privates' }
AbCodingAgentBuilder >> applyModelTo: aTopic [
	| modelOption |
	self model ifNil: [ ^ self ].
	modelOption := aTopic session modelConfigOption.
	modelOption
		ifNotNil: [ aTopic setConfigOptionId: modelOption id value: self model ]
		ifNil: [ aTopic setConfigOptionId: 'model' value: self model ]
]

{ #category : 'callbacks' }
AbCodingAgentBuilder >> finalizeOnSessionEstablished: aTopic [
	self applyModeTo: aTopic.
	self applyModelTo: aTopic.
	super finalizeOnSessionEstablished: aTopic
]
