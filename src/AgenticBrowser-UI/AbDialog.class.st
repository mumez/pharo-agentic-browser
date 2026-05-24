Class {
	#name : 'AbDialog',
	#superclass : 'SpPresenter',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'private' }
AbDialog >> agentOptions [

	^ AbSettings default codingAgents collect: [ :each |
		(each at: 'name') -> (each at: 'command') ]
]
