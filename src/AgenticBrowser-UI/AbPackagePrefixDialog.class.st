Class {
	#name : 'AbPackagePrefixDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'prefixField',
		'okButton',
		'cancelButton',
		'prefix'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbPackagePrefixDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbPackagePrefixDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (self newLabel label: 'Package prefix (use * as wildcard, empty = new project):')
		  withConstraints: [ :c | c height: 24 ];
		  add: prefixField
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   addLast: cancelButton withConstraints: [ :c | c width: 80 ];
				   addLast: okButton withConstraints: [ :c | c width: 80 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbPackagePrefixDialog >> initializePresenters [

	prefixField := self newTextInput.
	prefixField placeholder: 'e.g. ACP-*'.

	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbPackagePrefixDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Target Packages';
		initialExtent: 400 @ 130
]

{ #category : 'private' }
AbPackagePrefixDialog >> onOkClicked [

	prefix := prefixField text trimmed.
	self withWindowDo: [ :w | w close ]
]

{ #category : 'api' }
AbPackagePrefixDialog >> prefix [
	^ prefix
]
