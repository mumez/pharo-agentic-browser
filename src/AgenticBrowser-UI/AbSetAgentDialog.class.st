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

{ #category : 'accessing' }
AbSetAgentDialog >> agentDropList [

	^ agentDropList
]

{ #category : 'accessing' }
AbSetAgentDialog >> cancelButton [

	^ cancelButton
]

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
				   add: self agentDropList;
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   "The leading expanding spacer keeps the row's width calculation stable on Pharo 14, where a row of only fixed-width buttons overflows past the window edge."
				   add: (self newLabel label: '') expand: true;
				   add: self cancelButton withConstraints: [ :c | c width: 80; height: 32 ];
				   add: self okButton withConstraints: [ :c | c width: 80; height: 32 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbSetAgentDialog >> initializePresenters [

	super initializePresenters.
	agentDropList := self newDropList.
	agentDropList items: self agentOptions.
	agentDropList display: [ :opt | opt key ].
	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbSetAgentDialog >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Set Agent';
		initialExtent: 400 @ 120;
		withoutButtons
]

{ #category : 'accessing' }
AbSetAgentDialog >> okButton [

	^ okButton
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
