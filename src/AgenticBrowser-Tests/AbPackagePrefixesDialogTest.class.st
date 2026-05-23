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
