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

{ #category : 'accessing' }
AbPackagePrefixesDialog >> cancelButton [

	^ cancelButton
]

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
		  add: self prefixField
		  withConstraints: [ :c | c height: 32 ];
		  add: (SpBoxLayout newLeftToRight
				   "The leading expanding spacer keeps the row's width calculation stable on Pharo 14, where a row of only fixed-width buttons overflows past the window edge."
				   add: (self newLabel label: '') expand: true;
				   add: self cancelButton withConstraints: [ :c | c width: 80; height: 32 ];
				   add: self okButton withConstraints: [ :c | c width: 80; height: 32 ];
				   yourself)
		  withConstraints: [ :c | c height: 32 ];
		  yourself
]

{ #category : 'initialization' }
AbPackagePrefixesDialog >> initializePresenters [

	super initializePresenters.
	prefixField := self newTextInput.
	prefixField placeholder: 'e.g. ACP-*, BaselineOfACP'.

	okButton := self newButton label: 'OK'.
	cancelButton := self newButton label: 'Cancel'
]

{ #category : 'initialization' }
AbPackagePrefixesDialog >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Target Packages';
		initialExtent: 500 @ 130;
		withoutButtons
]

{ #category : 'accessing' }
AbPackagePrefixesDialog >> okButton [

	^ okButton
]

{ #category : 'private' }
AbPackagePrefixesDialog >> onOkClicked [

	self prefixPatterns: ((self prefixField text substrings: ',')
						   collect: [ :each | each trimmed ]
						   thenSelect: [ :each | each isNotEmpty ]).
	self withWindowDo: [ :w | w close ]
]

{ #category : 'accessing' }
AbPackagePrefixesDialog >> prefixField [

	^ prefixField
]

{ #category : 'accessing' }
AbPackagePrefixesDialog >> prefixPatterns [
	^ prefixPatterns ifNil: [ #() ]
]

{ #category : 'accessing' }
AbPackagePrefixesDialog >> prefixPatterns: aCollection [
	prefixPatterns := aCollection.
	prefixField ifNotNil: [
		prefixField text: (', ' join: aCollection asSortedCollection)
	]
]
