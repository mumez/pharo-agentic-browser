Class {
	#name : 'AbSettingsPresenterTest',
	#superclass : 'AbTestCase',
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

{ #category : 'tests' }
AbSettingsPresenterTest >> testAiTimeoutOptionDropListShowsDefaultSelection [
	self
		assert: presenter aiTimeoutOptionDropList selectedItem
		equals: (AbConstants defaultApprovalOptions
			detect: [ :assoc | assoc value = AbConstants rejectOnce ]) key
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testExportTimeoutOptionDropListShowsDefaultSelection [
	self
		assert: presenter exportTimeoutOptionDropList selectedItem
		equals: (AbConstants defaultApprovalOptions
			detect: [ :assoc | assoc value = AbConstants rejectOnce ]) key
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUseDefaultMcpServersCheckboxShowsDefaultValue [
	self assert: presenter useDefaultMcpServersCheckbox state equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesIntegerFieldsToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter watcherThrottleField text: '5'.
	presenter aiTimeoutField text: '600'.
	presenter exportTimeoutField text: '60'.
	presenter saveSettings.
	self assert: s watcherMessageThrottleSeconds equals: 5.
	self assert: s aiPermissionWaitTimeoutSeconds equals: 600.
	self assert: s exportApprovalWaitTimeoutSeconds equals: 60
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesOptionDropListsToSettings [
	| s allowOnceLabel |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	allowOnceLabel := (AbConstants defaultApprovalOptions
		detect: [ :assoc | assoc value = AbConstants allowOnce ]) key.
	presenter aiTimeoutOptionDropList selectItem: allowOnceLabel.
	presenter exportTimeoutOptionDropList selectItem: allowOnceLabel.
	presenter saveSettings.
	self assert: s aiPermissionTimeoutOption equals: AbConstants allowOnce.
	self assert: s exportApprovalTimeoutOption equals: AbConstants allowOnce
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesBooleanCheckboxToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter useDefaultMcpServersCheckbox state: false.
	presenter saveSettings.
	self assert: s useDefaultMcpServers equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveActionCalledOnSave [
	| called |
	called := false.
	presenter saveAction: [ called := true ].
	presenter saveSettings.
	self assert: called
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testGoalSettingsCommandFieldShowsDefaultValue [
	self assert: presenter goalSettingsCommandField text equals: '/goal'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUseCommandOnGoalSettingsCheckboxShowsDefaultValue [
	self assert: presenter useCommandOnGoalSettingsCheckbox state equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesGoalSettingsCommandToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter goalSettingsCommandField text: '/mygoal'.
	presenter saveSettings.
	self assert: s goalSettingsCommand equals: '/mygoal'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesUseCommandOnGoalSettingsToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter useCommandOnGoalSettingsCheckbox state: true.
	presenter saveSettings.
	self assert: s useCommandOnGoalSettings equals: true
]
