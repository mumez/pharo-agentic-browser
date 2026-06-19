Class {
	#name : 'AbCodingAgentBuilder',
	#superclass : 'AbElementBuilder',
	#instVars : [
		'agentArguments',
		'postConnectActions'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'initialization' }
AbCodingAgentBuilder >> initialize [
	super initialize.
	agentArguments := #().
	postConnectActions := OrderedCollection new.
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments [
	^ agentArguments
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> agentArguments: anArray [
	agentArguments := anArray
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> postConnectActions [
	^ postConnectActions
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

{ #category : 'configuring' }
AbCodingAgentBuilder >> mode: aModeName [
	self postConnectActions add: [ :topic |
		| modeOption |
		modeOption := topic session modeConfigOption.
		modeOption
			ifNotNil: [ topic setConfigOptionId: modeOption id value: aModeName ]
			ifNil: [ topic setConfigOptionId: 'mode' value: aModeName ] ]
]

{ #category : 'configuring' }
AbCodingAgentBuilder >> planMode [
	self mode: #plan
]
