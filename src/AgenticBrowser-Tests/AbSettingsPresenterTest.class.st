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
	presenter := AbSettingsPresenter on: AbSettings new
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

{ #category : 'tests' }
AbSettingsPresenterTest >> testWatcherThrottleFieldShowsDefaultValue [
	self assert: presenter watcherThrottleField text equals: '2'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testAiTimeoutFieldShowsDefaultValue [
	self assert: presenter aiTimeoutField text equals: '1800'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testExportTimeoutFieldShowsDefaultValue [
	self assert: presenter exportTimeoutField text equals: '30'
]
