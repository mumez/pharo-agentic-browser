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
		  add: inputField;
		  add: sendButton withConstraints: [ :c | c width: 80 ];
		  add: cancelButton withConstraints: [ :c | c width: 60 ];
		  yourself
]

{ #category : 'actions' }
AbNormalInputPresenter >> onSendAction: aBlock [

	sendButton action: aBlock
]

{ #category : 'actions' }
AbNormalInputPresenter >> onCancelAction: aBlock [

	cancelButton action: aBlock
]

{ #category : 'accessing' }
AbNormalInputPresenter >> inputText [

	^ inputField text
]

{ #category : 'accessing' }
AbNormalInputPresenter >> clearInput [

	inputField text: ''
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

	^ sendButton label
]

{ #category : 'testing' }
AbNormalInputPresenter >> cancelButtonLabel [

	^ cancelButton label
]

{ #category : 'testing' }
AbNormalInputPresenter >> inputPlaceholder [

	^ inputField placeholder
]
