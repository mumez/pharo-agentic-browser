Class {
	#name : 'AbNormalInputPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'inputField',
		'sendButton',
		'cancelButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'accessing' }
AbNormalInputPresenter >> cancelButton [

	^ cancelButton
]

{ #category : 'testing' }
AbNormalInputPresenter >> cancelButtonLabel [

	^ self cancelButton label
]

{ #category : 'actions' }
AbNormalInputPresenter >> cancelEnabled: aBoolean [

	self cancelButton enabled: aBoolean
]

{ #category : 'accessing' }
AbNormalInputPresenter >> clearInput [

	self inputField text: ''
]

{ #category : 'layout' }
AbNormalInputPresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  add: self inputField;
		  add: self sendButton withConstraints: [ :c | c width: 80 ];
		  add: self cancelButton withConstraints: [ :c | c width: 60 ];
		  yourself
]

{ #category : 'initialization' }
AbNormalInputPresenter >> initializePresenters [

	super initializePresenters.
	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'.

	cancelButton := self newButton.
	cancelButton label: 'Cancel'
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputField [

	^ inputField
]

{ #category : 'testing' }
AbNormalInputPresenter >> inputPlaceholder [

	^ self inputField placeholder
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputText [

	^ self inputField text
]

{ #category : 'testing' }
AbNormalInputPresenter >> isCancelEnabled [

	^ self cancelButton isEnabled
]

{ #category : 'actions' }
AbNormalInputPresenter >> onCancelAction: aBlock [

	self cancelButton action: aBlock
]

{ #category : 'actions' }
AbNormalInputPresenter >> onSendAction: aBlock [

	self sendButton action: aBlock
]

{ #category : 'accessing' }
AbNormalInputPresenter >> sendButton [

	^ sendButton
]

{ #category : 'testing' }
AbNormalInputPresenter >> sendButtonLabel [

	^ self sendButton label
]
