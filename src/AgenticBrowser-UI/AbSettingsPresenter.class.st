Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'settings',
		'saveAction'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AbSettingsPresenter class >> openOn: anAbSettings [
	| presenter |
	presenter := self new.
	presenter settings: anAbSettings.
	presenter open.
	^ presenter
]

{ #category : 'accessing' }
AbSettingsPresenter >> settings [
	^ settings
]

{ #category : 'accessing' }
AbSettingsPresenter >> settings: anAbSettings [
	settings := anAbSettings
]

{ #category : 'actions' }
AbSettingsPresenter >> onSaveAction: aBlock [
	self saveAction: aBlock
]

{ #category : 'initialization' }
AbSettingsPresenter >> initialize [
	super initialize.
	self saveAction: []
]

{ #category : 'private' }
AbSettingsPresenter >> saveAction [
	^ saveAction
]

{ #category : 'private' }
AbSettingsPresenter >> saveAction: aBlock [
	saveAction := aBlock
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializePresenters [
	super initializePresenters
]

{ #category : 'layout' }
AbSettingsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Settings';
		initialExtent: 420 @ 320
]
