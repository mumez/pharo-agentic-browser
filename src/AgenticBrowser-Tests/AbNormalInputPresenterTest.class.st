Class {
	#name : 'AbNormalInputPresenterTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbNormalInputPresenterTest >> setUp [

	super setUp.
	presenter := AbNormalInputPresenter new.
	presenter initializePresenters
]

{ #category : 'running' }
AbNormalInputPresenterTest >> tearDown [

	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testInsertMentionAppendsToExistingText [

	presenter inputField text: 'Hello'.
	presenter insertMention: '@Foo>>bar'.
	self assert: presenter inputText equals: 'Hello @Foo>>bar '
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testInsertMentionIntoEmptyField [

	presenter clearInput.
	presenter insertMention: '@Foo>>bar'.
	self assert: presenter inputText equals: '@Foo>>bar '
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testMentionStringForClass [

	self
		assert: (presenter mentionStringFor: AbNormalInputPresenter)
		equals: '@AbNormalInputPresenter'
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testMentionStringForClassMethod [

	| method |
	method := AbTopicManager class >> #default.
	self
		assert: (presenter mentionStringFor: method)
		equals: '@AbTopicManager class>>default'
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testMentionStringForInstanceMethod [

	| method |
	method := AbNormalInputPresenter >> #inputText.
	self
		assert: (presenter mentionStringFor: method)
		equals: '@AbNormalInputPresenter>>inputText'
]

{ #category : 'tests' }
AbNormalInputPresenterTest >> testMentionStringForNilReturnsEmpty [

	self assert: (presenter mentionStringFor: nil) equals: ''
]
