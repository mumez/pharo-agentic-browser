Class {
	#name : 'AbPackagePrefixesDialogTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbPackagePrefixesDialogTest >> testPrefixPatternsSetsFieldTextSorted [

	| dialog |
	dialog := AbPackagePrefixesDialog new.
	dialog prefixPatterns: #('Zzz-*' 'AAA-*' 'Mmm-*') asOrderedCollection.
	self assert: dialog prefixField text equals: 'AAA-*, Mmm-*, Zzz-*'
]

{ #category : 'tests' }
AbPackagePrefixesDialogTest >> testPrefixPatternsSetsFieldTextForEmptyCollection [

	| dialog |
	dialog := AbPackagePrefixesDialog new.
	dialog prefixPatterns: #().
	self assert: dialog prefixField text equals: ''
]

{ #category : 'tests' }
AbPackagePrefixesDialogTest >> testPrefixPatternsReturnsSameCollection [

	| dialog patterns |
	dialog := AbPackagePrefixesDialog new.
	patterns := #('ACP-*' 'BaselineOfACP') asOrderedCollection.
	dialog prefixPatterns: patterns.
	self assert: (dialog prefixPatterns includesAll: patterns)
]

{ #category : 'tests' }
AbPackagePrefixesDialogTest >> testButtonsFitInsideWindow [

	| dialog window windowMorph |
	"Morph bounds are not laid out in a headless image, so this layout check needs a real display."
	SmalltalkImage current isInteractiveGraphic ifFalse: [ ^ self skip ].
	dialog := AbPackagePrefixesDialog new.
	window := dialog openDialog.
	[
	windowMorph := window adapter widget.
	windowMorph fullBounds.
	self assert: (windowMorph bounds containsRect: dialog okButton adapter widget bounds).
	self assert: (windowMorph bounds containsRect: dialog cancelButton adapter widget bounds) ]
		ensure: [ window close ]
]
