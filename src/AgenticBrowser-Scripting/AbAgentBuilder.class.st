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

{ #category : 'configuring' }
AbCodingAgentBuilder >> claude [
	arguments := #( 'claude-agent-acp' )
]

{ #category : 'configuring' }
AbCodingAgentBuilder >> codex [
	arguments := #( 'codex-acp' )
]

{ #category : 'configuring' }
AbCodingAgentBuilder >> gemini [
	arguments := #( 'gemini' '--acp' )
]

{ #category : 'configuring' }
AbCodingAgentBuilder >> opencode [
	arguments := #( 'opencode' 'acp' )
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
