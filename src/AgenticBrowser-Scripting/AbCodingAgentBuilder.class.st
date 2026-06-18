Class {
	#name : 'AbCodingAgentBuilder',
	#superclass : 'Object',
	#instVars : [
		'arguments',
		'postConnectActions'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'initialization' }
AbCodingAgentBuilder >> initialize [
	super initialize.
	arguments := #( 'claude-agent-acp' ).
	postConnectActions := OrderedCollection new.
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> arguments [
	^ arguments
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> arguments: anArray [
	arguments := anArray
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> postConnectActions [
	^ postConnectActions
]

{ #category : 'accessing' }
AbCodingAgentBuilder >> useAgentArgumentsAt: agentName [
	self arguments: (AbSettings default agentArgumentsPresets at: agentName)
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
AbCodingAgentBuilder >> planMode [
	postConnectActions add: [ :topic |
		| modeOption |
		modeOption := topic session modeConfigOption.
		modeOption
			ifNotNil: [ topic setConfigOptionId: modeOption id value: 'plan' ]
			ifNil: [ topic setConfigOptionId: 'mode' value: 'plan' ] ]
]

{ #category : 'configuring' }
AbCodingAgentBuilder >> configure: aBlock [
	aBlock value: self.
	^ self
]
