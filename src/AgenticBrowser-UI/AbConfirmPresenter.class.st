Class {
	#name : 'AbConfirmPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'confirmationLabel',
		'confirmButton',
		'denyButton',
		'optionDropList',
		'approvalOptions'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbConfirmPresenter >> initializePresenters [

	super initializePresenters.
	confirmationLabel := self newText.
	confirmationLabel beNotEditable.
	optionDropList := self newDropList.
	optionDropList startWithoutSelection.

	confirmButton := self newButton.
	confirmButton label: 'Confirm'.

	denyButton := self newButton.
	denyButton label: 'Deny'.
	self approvalOptions: self defaultApprovalOptions
]

{ #category : 'layout' }
AbConfirmPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  borderWidth: 6;
		  spacing: 4;
		  add: self confirmationLabel;
		  add: (SpBoxLayout newLeftToRight
				   add: self optionDropList;
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

{ #category : 'accessing' }
AbConfirmPresenter >> optionDropList [

	^ optionDropList
]

{ #category : 'accessing' }
AbConfirmPresenter >> approvalOptions [

	^ approvalOptions ifNil: [ #() ]
]

{ #category : 'accessing' }
AbConfirmPresenter >> approvalOptions: aCollection [

	| labels |
	approvalOptions := (aCollection ifNil: [ #() ]) asArray.
	labels := approvalOptions collect: [ :assoc | assoc key ].
	self optionDropList items: labels asArray.
	labels
		ifEmpty: [ self optionDropList startWithoutSelection ]
		ifNotEmpty: [ self optionDropList selectItem: labels first ]
]

{ #category : 'private' }
AbConfirmPresenter >> defaultApprovalOptions [

	^ {
		  'Confirm' -> #allowOnce.
		  'Deny' -> #rejectOnce }
]

{ #category : 'accessing' }
AbConfirmPresenter >> selectedOptionId [

	| selectedLabel selectedOption |
	self approvalOptions ifEmpty: [ ^ #allowOnce ].
	selectedLabel := self optionDropList selectedItem
		                 ifNil: [ self approvalOptions first key ].
	selectedOption := self approvalOptions
		                  detect: [ :assoc | assoc key = selectedLabel ]
		                  ifNone: [ self approvalOptions first ].
	^ selectedOption value
]

{ #category : 'testing' }
AbConfirmPresenter >> optionLabels [

	^ self approvalOptions collect: [ :assoc | assoc key ]
]

{ #category : 'testing' }
AbConfirmPresenter >> selectOptionNamed: aString [

	self optionDropList selectItem: aString
]
