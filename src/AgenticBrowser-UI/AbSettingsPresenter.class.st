Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'saveAction',
		'watcherThrottleField',
		'aiTimeoutField',
		'exportTimeoutField'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'accessing' }
AbSettingsPresenter >> settings [
	^ self model
]

{ #category : 'actions' }
AbSettingsPresenter >> onSaveAction: aBlock [
	self saveAction: aBlock
]

{ #category : 'initialization' }
AbSettingsPresenter >> initialize [
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
	self model ifNil: [ ^ self ].

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
