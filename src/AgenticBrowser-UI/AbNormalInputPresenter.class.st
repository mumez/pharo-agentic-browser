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

{ #category : 'initialization' }
AbNormalInputPresenter >> initializePresenters [

	inputField := self newText.
	inputField placeholder: 'Type your request...'.

	sendButton := self newButton.
	sendButton label: 'Send'.

	cancelButton := self newButton.
	cancelButton label: 'Cancel'
]

{ #category : 'layout' }
AbNormalInputPresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  add: self inputField;
		  add: self sendButton withConstraints: [ :c | c width: 80 ];
		  add: self cancelButton withConstraints: [ :c | c width: 60 ];
		  yourself
]

{ #category : 'actions' }
AbNormalInputPresenter >> onSendAction: aBlock [

	self sendButton action: aBlock
]

{ #category : 'actions' }
AbNormalInputPresenter >> onCancelAction: aBlock [

	self cancelButton action: aBlock
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputText [

	^ self inputField text
]

{ #category : 'accessing' }
AbNormalInputPresenter >> clearInput [

	self inputField text: ''
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputField [

	^ inputField
]

{ #category : 'accessing' }
AbNormalInputPresenter >> sendButton [

	^ sendButton
]

{ #category : 'accessing' }
AbNormalInputPresenter >> cancelButton [

	^ cancelButton
]

{ #category : 'testing' }
AbNormalInputPresenter >> sendButtonLabel [

	^ self sendButton label
]

{ #category : 'testing' }
AbNormalInputPresenter >> cancelButtonLabel [

	^ self cancelButton label
]

{ #category : 'testing' }
AbNormalInputPresenter >> inputPlaceholder [

	^ self inputField placeholder
]

{ #category : 'testing' }
AbNormalInputPresenter >> isCancelEnabled [

	^ self cancelButton isEnabled
]

{ #category : 'actions' }
AbNormalInputPresenter >> cancelEnabled: aBoolean [

	self cancelButton enabled: aBoolean
]
