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
		  add: confirmationLabel;
		  add: (SpBoxLayout newLeftToRight
				   addLast: confirmButton withConstraints: [ :c | c width: 100 ];
				   addLast: denyButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmationText: aString [

	confirmationLabel text: aString
]

{ #category : 'actions' }
AbConfirmPresenter >> onConfirmAction: aBlock [

	confirmButton action: aBlock
]

{ #category : 'actions' }
AbConfirmPresenter >> onDenyAction: aBlock [

	denyButton action: aBlock
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

	^ confirmButton label
]

{ #category : 'testing' }
AbConfirmPresenter >> denyButtonLabel [

	^ denyButton label
]
