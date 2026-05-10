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

{ #category : 'accessing' }
AbConfirmPresenter >> approvalOptions [

	^ approvalOptions
]

{ #category : 'accessing' }
AbConfirmPresenter >> approvalOptions: aCollection [

	| labels |
	approvalOptions := (aCollection ifNil: [ #() ]) asArray.
	labels := approvalOptions collect: [ :assoc | assoc key ].
	self optionDropList items: labels.
	labels
		ifEmpty: [ self optionDropList startWithoutSelection ]
		ifNotEmpty: [ self optionDropList selectItem: labels first ]
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmButton [

	^ confirmButton
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmButtonLabel [

	^ self confirmButton label
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmationLabel [

	^ confirmationLabel
]

{ #category : 'accessing' }
AbConfirmPresenter >> confirmationText: aString [

	self confirmationLabel text: aString
]

{ #category : 'private' }
AbConfirmPresenter >> defaultApprovalOptions [

	^ {
		  'Confirm' -> #allow_once.
		  'Deny' -> #reject_once }
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
AbConfirmPresenter >> denyButton [

	^ denyButton
]

{ #category : 'accessing' }
AbConfirmPresenter >> denyButtonLabel [

	^ self denyButton label
]

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

{ #category : 'actions' }
AbConfirmPresenter >> onConfirmAction: aBlock [

	self confirmButton action: aBlock
]

{ #category : 'actions' }
AbConfirmPresenter >> onDenyAction: aBlock [

	self denyButton action: aBlock
]

{ #category : 'accessing' }
AbConfirmPresenter >> optionDropList [

	^ optionDropList
]

{ #category : 'accessing' }
AbConfirmPresenter >> optionLabels [

	^ self approvalOptions collect: [ :assoc | assoc key ]
]

{ #category : 'actions' }
AbConfirmPresenter >> selectOptionNamed: aString [

	self optionDropList selectItem: aString
]

{ #category : 'accessing' }
AbConfirmPresenter >> selectedOptionId [

	| idx |
	self approvalOptions ifEmpty: [ ^ #allow_once ].
	idx := self optionDropList selectedIndex.
	idx = 0 ifTrue: [ ^ self approvalOptions first value ].
	^ (self approvalOptions at: idx) value
]
