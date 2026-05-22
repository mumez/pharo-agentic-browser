Class {
	#name : 'AbSettingsPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSettingsPresenterTest >> setUp [
	super setUp.
	presenter := AbSettingsPresenter new.
	presenter settings: AbSettings new.
	presenter initializePresenters
]

{ #category : 'running' }
AbSettingsPresenterTest >> tearDown [
	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSettingsIsAssigned [
	self assert: (presenter settings isKindOf: AbSettings)
]
