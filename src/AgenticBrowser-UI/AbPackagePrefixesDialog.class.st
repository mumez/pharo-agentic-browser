Class {
	#name : 'AbPackagePrefixesDialog',
	#superclass : 'SpPresenter',
	#instVars : [
		'prefixField',
		'okButton',
		'cancelButton',
		'prefixPatterns'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbPackagePrefixesDialog >> connectPresenters [

	okButton action: [ self onOkClicked ].
	cancelButton action: [ self withWindowDo: [ :w | w close ] ]
]

{ #category : 'layout' }
AbPackagePrefixesDialog >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (self newLabel label: 'Package prefix patterns (comma-separated, * as wildcard):')
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
AbPackagePrefixesDialog >> initializePresenters [

	prefixField := self newTextInput.
	prefixField placeholder: 'e.g. ACP-*, BaselineOfACP'.

	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbPackagePrefixesDialog >> initializeWindow: aWindowPresenter [

	aWindowPresenter
		title: 'Target Packages';
		initialExtent: 500 @ 130
]

{ #category : 'private' }
AbPackagePrefixesDialog >> onOkClicked [

	prefixPatterns := (prefixField text substrings: ',')
		                  collect: [ :each | each trimmed ]
		                  thenSelect: [ :each | each isNotEmpty ].
	self withWindowDo: [ :w | w close ]
]

{ #category : 'accessing' }
AbPackagePrefixesDialog >> prefixPatterns [
	^ prefixPatterns ifNil: [ #() ]
]
