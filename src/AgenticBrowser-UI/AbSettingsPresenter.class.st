Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'settings',
		'saveAction',
		'watcherThrottleField',
		'aiTimeoutField',
		'exportTimeoutField'
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
	settings := AbSettings new.
	saveAction := [].
	super initialize
]

{ #category : 'private' }
AbSettingsPresenter >> saveAction [
	^ saveAction
]

{ #category : 'private' }
AbSettingsPresenter >> saveAction: aBlock [
	saveAction := aBlock
]

{ #category : 'accessing' }
AbSettingsPresenter >> watcherThrottleField [
	^ watcherThrottleField
]

{ #category : 'accessing' }
AbSettingsPresenter >> aiTimeoutField [
	^ aiTimeoutField
]

{ #category : 'accessing' }
AbSettingsPresenter >> exportTimeoutField [
	^ exportTimeoutField
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializePresenters [
	super initializePresenters.
	watcherThrottleField := self newTextInput.
	watcherThrottleField text: self settings watcherMessageThrottleSeconds printString.

	aiTimeoutField := self newTextInput.
	aiTimeoutField text: self settings aiPermissionWaitTimeoutSeconds printString.

	exportTimeoutField := self newTextInput.
	exportTimeoutField text: self settings exportApprovalWaitTimeoutSeconds printString
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
