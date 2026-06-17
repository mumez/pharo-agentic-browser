Class {
	#name : 'AbAgentBuilder',
	#superclass : 'Object',
	#instVars : [
		'arguments',
		'postConnectActions'
	],
	#category : 'AgenticBrowser-Scripting',
	#package : 'AgenticBrowser-Scripting'
}

{ #category : 'initialization' }
AbAgentBuilder >> initialize [
	super initialize.
	arguments := #( 'claude-agent-acp' ).
	postConnectActions := OrderedCollection new.
]

{ #category : 'accessing' }
AbAgentBuilder >> arguments [
	^ arguments
]

{ #category : 'accessing' }
AbAgentBuilder >> arguments: anArray [
	arguments := anArray
]

{ #category : 'accessing' }
AbAgentBuilder >> postConnectActions [
	^ postConnectActions
]

{ #category : 'configuring' }
AbAgentBuilder >> claude [
	arguments := #( 'claude-agent-acp' )
]

{ #category : 'configuring' }
AbAgentBuilder >> codex [
	arguments := #( 'codex-acp' )
]

{ #category : 'configuring' }
AbAgentBuilder >> gemini [
	arguments := #( 'gemini' '--acp' )
]

{ #category : 'configuring' }
AbAgentBuilder >> opencode [
	arguments := #( 'opencode' 'acp' )
]

{ #category : 'configuring' }
AbAgentBuilder >> planMode [
	postConnectActions add: [ :topic |
		| modeOption |
		modeOption := topic session modeConfigOption.
		modeOption 
			ifNotNil: [ topic setConfigOptionId: modeOption id value: 'plan' ]
			ifNil: [ topic setConfigOptionId: 'mode' value: 'plan' ] ]
]

{ #category : 'configuring' }
AbAgentBuilder >> configure: aBlock [
	aBlock value: self.
	^ self
]
