Class {
	#name : 'AbSettingsPresenter',
	#superclass : 'SpPresenterWithModel',
	#instVars : [
		'saveAction',
		'watcherThrottleField',
		'aiTimeoutField',
		'exportTimeoutField',
		'aiTimeoutOptionDropList',
		'exportTimeoutOptionDropList',
		'useDefaultMcpServersCheckbox',
		'saveButton',
		'cancelButton'
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

{ #category : 'accessing' }
AbSettingsPresenter >> useDefaultMcpServersCheckbox [
	^ useDefaultMcpServersCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> saveButton [
	^ saveButton
]

{ #category : 'accessing' }
AbSettingsPresenter >> cancelButton [
	^ cancelButton
]

{ #category : 'actions' }
AbSettingsPresenter >> saveSettings [
	self settings watcherMessageThrottleSeconds: watcherThrottleField text asInteger.
	self settings aiPermissionWaitTimeoutSeconds: aiTimeoutField text asInteger.
	self settings exportApprovalWaitTimeoutSeconds: exportTimeoutField text asInteger.
	self settings aiPermissionTimeoutOption: (self optionIdForLabel: aiTimeoutOptionDropList selectedItem).
	self settings exportApprovalTimeoutOption: (self optionIdForLabel: exportTimeoutOptionDropList selectedItem).
	self settings useDefaultMcpServers: useDefaultMcpServersCheckbox state.
	self saveAction value
]

{ #category : 'private' }
AbSettingsPresenter >> optionIdForLabel: aLabel [
	^ (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc key = aLabel ]
		ifNone: [ AbConstants defaultApprovalOptions first ]) value
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
		selectItem: (self labelForOptionId: self settings exportApprovalTimeoutOption).

	useDefaultMcpServersCheckbox := self newCheckBox.
	useDefaultMcpServersCheckbox label: 'Use default MCP servers'.
	useDefaultMcpServersCheckbox state: self settings useDefaultMcpServers.

	saveButton := self newButton.
	saveButton label: 'Save'.
	saveButton action: [ self saveSettings. self window close ].

	cancelButton := self newButton.
	cancelButton label: 'Cancel'.
	cancelButton action: [ self window close ]
]

{ #category : 'layout' }
AbSettingsPresenter >> defaultLayout [
	^ SpBoxLayout newTopToBottom
		borderWidth: 10;
		spacing: 6;
		add: (self labeledRow: 'Watcher throttle (seconds):' field: watcherThrottleField);
		add: (self labeledRow: 'AI permission timeout (seconds):' field: aiTimeoutField);
		add: (self labeledRow: 'AI timeout option:' field: aiTimeoutOptionDropList);
		add: (self labeledRow: 'Export timeout (seconds):' field: exportTimeoutField);
		add: (self labeledRow: 'Export timeout option:' field: exportTimeoutOptionDropList);
		add: useDefaultMcpServersCheckbox withConstraints: [ :c | c height: 28 ];
		addLast: self actionButtonsLayout withConstraints: [ :c | c height: 34 ];
		yourself
]

{ #category : 'layout' }
AbSettingsPresenter >> labeledRow: aLabelString field: aPresenter [
	^ SpBoxLayout newLeftToRight
		spacing: 6;
		add: (self newLabel label: aLabelString)
			withConstraints: [ :c | c width: 230 ];
		add: aPresenter;
		yourself
]

{ #category : 'layout' }
AbSettingsPresenter >> actionButtonsLayout [
	^ SpBoxLayout newLeftToRight
		addLast: saveButton withConstraints: [ :c | c width: 80 ];
		addLast: cancelButton withConstraints: [ :c | c width: 80 ];
		yourself
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Settings';
		initialExtent: 420 @ 320
]
