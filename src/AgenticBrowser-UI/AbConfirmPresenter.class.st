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
	approvalOptions ifEmpty: [ approvalOptions := self defaultApprovalOptions ].
	labels := approvalOptions collect: [ :assoc | assoc key ].
	self optionDropList items: labels.
	self updateActionButtons.
	labels
		ifEmpty: [ self optionDropList startWithoutSelection ]
		ifNotEmpty: [ self optionDropList selectItem: labels first ].
	self layout: self defaultLayout
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

	^ AbConstants defaultApprovalOptions copy
]

{ #category : 'layout' }
AbConfirmPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  borderWidth: 6;
		  spacing: 4;
		  add: self confirmationLabel;
		  add: self optionAndActionButtonsLayout
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

{ #category : 'layout' }
AbConfirmPresenter >> optionAndActionButtonsLayout [

	| row |
	row := SpBoxLayout newLeftToRight
		       add: self optionDropList;
		       addLast: self confirmButton withConstraints: [ :c | c width: 100 ].
	self showsDenyButton ifTrue: [
		row addLast: self denyButton withConstraints: [ :c | c width: 80 ] ].
	^ row yourself
]

{ #category : 'actions' }
AbConfirmPresenter >> selectOptionNamed: aString [

	self optionDropList selectItem: aString
]

{ #category : 'accessing' }
AbConfirmPresenter >> selectedOptionId [

	| selectedLabel selectedOption |
	self approvalOptions ifEmpty: [ ^ AbConstants allowOnce ].
	selectedLabel := self optionDropList selectedItem.
	selectedLabel ifNil: [ ^ self approvalOptions first value ].
	selectedOption := self approvalOptions
		                  detect: [ :assoc | assoc key = selectedLabel ]
		                  ifNone: [ self approvalOptions first ].
	^ selectedOption value
]

{ #category : 'accessing' }
AbConfirmPresenter >> selectedOptionIdForDenyAction [

	self showsDenyButton ifTrue: [ ^ self approvalOptions second value ].
	^ self selectedOptionId
]

{ #category : 'layout' }
AbConfirmPresenter >> showsDenyButton [

	^ self approvalOptions size = 2
]

{ #category : 'private' }
AbConfirmPresenter >> updateActionButtons [

	self confirmButton label: (self showsDenyButton
			 ifTrue: [ 'Confirm' ]
			 ifFalse: [ 'Submit' ])
]
