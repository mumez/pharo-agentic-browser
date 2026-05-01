Class {
	#name : 'AbConfirmPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'confirmationLabel',
		'confirmButton',
		'denyButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbConfirmPresenter >> initializePresenters [

	confirmationLabel := self newText.
	confirmationLabel beNotEditable.

	confirmButton := self newButton.
	confirmButton label: 'Confirm'.

	denyButton := self newButton.
	denyButton label: 'Deny'
]

{ #category : 'layout' }
AbConfirmPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  borderWidth: 6;
		  spacing: 4;
		  add: self confirmationLabel;
		  add: (SpBoxLayout newLeftToRight
				   addLast: self confirmButton withConstraints: [ :c | c width: 100 ];
				   addLast: self denyButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmationText: aString [

	self confirmationLabel text: aString
]

{ #category : 'actions' }
AbConfirmPresenter >> onConfirmAction: aBlock [

	self confirmButton action: aBlock
]

{ #category : 'actions' }
AbConfirmPresenter >> onDenyAction: aBlock [

	self denyButton action: aBlock
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmationLabel [

	^ confirmationLabel
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmButton [

	^ confirmButton
]

{ #category : 'accessing' }
AbConfirmPresenter >> denyButton [

	^ denyButton
]

{ #category : 'testing' }
AbConfirmPresenter >> confirmButtonLabel [

	^ self confirmButton label
]

{ #category : 'testing' }
AbConfirmPresenter >> denyButtonLabel [

	^ self denyButton label
]
