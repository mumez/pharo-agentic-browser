Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'saveAction',
		'watcherThrottleField',
		'aiTimeoutField',
		'exportTimeoutField',
		'aiTimeoutOptionDropList',
		'exportTimeoutOptionDropList'
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

{ #category : 'accessing' }
AbSettingsPresenter >> aiTimeoutOptionDropList [
	^ aiTimeoutOptionDropList
]

{ #category : 'accessing' }
AbSettingsPresenter >> exportTimeoutOptionDropList [
	^ exportTimeoutOptionDropList
]

{ #category : 'private' }
AbSettingsPresenter >> approvalOptionLabels [
	^ AbConstants defaultApprovalOptions collect: [ :assoc | assoc key ]
]

{ #category : 'private' }
AbSettingsPresenter >> labelForOptionId: anOptionSymbol [
	^ (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc value = anOptionSymbol ]
		ifNone: [ AbConstants defaultApprovalOptions first ]) key
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
	exportTimeoutField text: self settings exportApprovalWaitTimeoutSeconds printString.

	aiTimeoutOptionDropList := self newDropList.
	aiTimeoutOptionDropList items: self approvalOptionLabels.
	aiTimeoutOptionDropList
		selectItem: (self labelForOptionId: self settings aiPermissionTimeoutOption).

	exportTimeoutOptionDropList := self newDropList.
	exportTimeoutOptionDropList items: self approvalOptionLabels.
	exportTimeoutOptionDropList
		selectItem: (self labelForOptionId: self settings exportApprovalTimeoutOption)
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
