Class {
	#name : 'AbSetAgentDialog',
	#superclass : 'AbDialog',
	#instVars : [
		'agentDropList',
		'okButton',
		'cancelButton',
		'selectedArguments'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbSetAgentDialog >> connectPresenters [

	okButton action: [
		selectedArguments := agentDropList selectedItem value.
		self withWindowDo: [ :w | w close ] ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbSetAgentDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (SpBoxLayout newLeftToRight
				   add: (self newLabel label: 'Agent:') withConstraints: [ :c | c width: 80 ];
				   add: agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbSetAgentDialog >> initializePresenters [

	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].
	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbSetAgentDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Set Agent';
		initialExtent: 400 @ 120
]

{ #category : 'accessing' }
AbSetAgentDialog >> selectCurrentArguments: anArray [

	| matching |
	matching := agentDropList items detect: [ :opt | opt value = anArray ] ifNone: [ nil ].
	matching ifNotNil: [ agentDropList selectItem: matching ]
]

{ #category : 'accessing' }
AbSetAgentDialog >> selectedArguments [
	^ selectedArguments
]
