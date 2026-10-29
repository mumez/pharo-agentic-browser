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

{ #category : 'accessing' }
AbSettingsPresenterTest >> presenter [
	^ presenter
]

{ #category : 'accessing' }
AbSettingsPresenterTest >> presenter: anAbSettingsPresenter [
	presenter := anAbSettingsPresenter
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
AbSettingsPresenterTest >> testGoalSetCommandFieldShowsDefaultValue [
	self assert: presenter goalSetCommandField text equals: '/goal'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUseCommandOnGoalSetCheckboxShowsDefaultValue [
	self assert: presenter useCommandOnGoalSetCheckbox state equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesGoalSetCommandToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter goalSetCommandField text: '/mygoal'.
	presenter saveSettings.
	self assert: s goalSetCommand equals: '/mygoal'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesUseCommandOnGoalSetToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter useCommandOnGoalSetCheckbox state: true.
	presenter saveSettings.
	self assert: s useCommandOnGoalSet equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUseStBuddySkillOnInitialPromptCheckboxShowsDefaultValue [
	self assert: presenter useStBuddySkillOnInitialPromptCheckbox state equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testInitialPromptSkillFieldShowsDefaultValue [
	self assert: presenter initialPromptSkillField text equals: '/smalltalk-dev:st-buddy'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUncheckingUseStBuddySkillCheckboxClearsInitialPromptSkillField [
	presenter useStBuddySkillOnInitialPromptCheckbox state: false.
	self assert: presenter initialPromptSkillField text equals: ''
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCheckingUseStBuddySkillCheckboxRestoresDefaultInitialPromptSkill [
	presenter useStBuddySkillOnInitialPromptCheckbox state: false.
	presenter useStBuddySkillOnInitialPromptCheckbox state: true.
	self assert: presenter initialPromptSkillField text equals: '/smalltalk-dev:st-buddy'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testEditingInitialPromptSkillFieldKeepsCheckboxState [
	presenter initialPromptSkillField text: '$st-buddy'.
	self assert: presenter useStBuddySkillOnInitialPromptCheckbox state equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testOpeningOnCustomInitialPromptSkillShowsItWithCheckboxOff [
	| s |
	s := AbSettings new.
	s initialPromptSkill: '$st-buddy'.
	presenter := AbSettingsPresenter on: s.
	self assert: presenter initialPromptSkillField text equals: '$st-buddy'.
	self deny: presenter useStBuddySkillOnInitialPromptCheckbox state
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesClearedInitialPromptSkillToSettings [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter useStBuddySkillOnInitialPromptCheckbox state: false.
	presenter saveSettings.
	self assert: s initialPromptSkill equals: ''.
	self deny: s useStBuddySkillOnInitialPrompt
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesCustomInitialPromptSkillWhileCheckboxIsOn [
	| s |
	s := AbSettings new.
	presenter := AbSettingsPresenter on: s.
	presenter initialPromptSkillField text: '$st-buddy'.
	presenter saveSettings.
	self assert: presenter useStBuddySkillOnInitialPromptCheckbox state equals: true.
	self assert: s initialPromptSkill equals: '$st-buddy'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testUseCritCheckboxShowsDefaultValue [
	self assert: self presenter useCritCheckbox state equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCritAllowUnauthenticatedNetworkCheckboxShowsDefaultValue [
	self assert: self presenter critAllowUnauthenticatedNetworkCheckbox state equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCritAllowUnauthenticatedNetworkCheckboxShowsSettingsValue [
	| s |
	s := AbSettings new.
	s critAllowUnauthenticatedNetwork: false.
	self presenter: (AbSettingsPresenter on: s).
	self assert: self presenter critAllowUnauthenticatedNetworkCheckbox state equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesCritAllowUnauthenticatedNetworkToSettings [
	| s |
	s := AbSettings new.
	self presenter: (AbSettingsPresenter on: s).
	self presenter critAllowUnauthenticatedNetworkCheckbox state: false.
	self presenter saveSettings.
	self assert: s critAllowUnauthenticatedNetwork equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCritPortRangeFieldShowsDefaultValue [
	self assert: self presenter critPortRangeField text equals: '9080-9100'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testValidationMessageLabelIsEmptyInitially [
	self assert: self presenter validationMessageLabel label isEmpty
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesUseCritToSettings [
	| s |
	s := AbSettings new.
	self presenter: (AbSettingsPresenter on: s).
	self presenter useCritCheckbox state: true.
	self presenter saveSettings.
	self assert: s useCrit equals: true
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWritesCritPortRangeToSettings [
	| s |
	s := AbSettings new.
	self presenter: (AbSettingsPresenter on: s).
	self presenter critPortRangeField text: '9200-9210'.
	self presenter saveSettings.
	self assert: s critPortRange equals: '9200-9210'
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWithInvalidCritPortRangeDoesNotWriteSettings [
	| s |
	s := AbSettings new.
	self presenter: (AbSettingsPresenter on: s).
	self presenter useCritCheckbox state: true.
	self presenter critPortRangeField text: '9100-9080'.
	self presenter saveSettings.
	self assert: s critPortRange equals: '9080-9100'.
	self assert: s useCrit equals: false
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWithInvalidCritPortRangeShowsValidationMessage [
	self presenter critPortRangeField text: 'abc'.
	self presenter saveSettings.
	self assert: (self presenter validationMessageLabel label includesSubstring: self presenter settings defaultCritPortRange)
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWithInvalidCritPortRangeDoesNotCallSaveAction [
	| called |
	called := false.
	self presenter saveAction: [ called := true ].
	self presenter critPortRangeField text: '9080-65536'.
	self presenter saveSettings.
	self deny: called
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveWithValidCritPortRangeClearsValidationMessage [
	self presenter critPortRangeField text: 'abc'.
	self presenter saveSettings.
	self presenter critPortRangeField text: '9080-9090'.
	self presenter saveSettings.
	self assert: self presenter validationMessageLabel label isEmpty
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveButtonKeepsWindowOpenWhenCritPortRangeIsInvalid [
	self presenter open.
	[
	self presenter critPortRangeField text: 'abc'.
	self presenter saveButton click.
	self assert: self presenter window isOpen ] ensure: [ self presenter window close ]
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveButtonClosesWindowWhenSettingsAreValid [
	self presenter open.
	[
	self presenter saveButton click.
	self deny: self presenter window isOpen ] ensure: [ self presenter window close ]
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCritSettingsAreShownByDefault [
	self assert: self presenter showsCritSettings.
	self assert: (self presenter layout allPresenters includes: self presenter useCritCheckbox).
	self assert: (self presenter layout allPresenters includes: self presenter critAllowUnauthenticatedNetworkCheckbox).
	self assert: (self presenter layout allPresenters includes: self presenter critPortRangeField)
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testCritSettingsAreHiddenWhenNotShown [
	self presenter showsCritSettings: false.
	self deny: (self presenter layout allPresenters includes: self presenter useCritCheckbox).
	self deny: (self presenter layout allPresenters includes: self presenter critAllowUnauthenticatedNetworkCheckbox).
	self deny: (self presenter layout allPresenters includes: self presenter critPortRangeField).
	self deny: (self presenter layout allPresenters includes: self presenter validationMessageLabel)
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testSaveIgnoresInvalidCritPortRangeWhenCritSettingsAreHidden [
	| s called |
	s := AbSettings new.
	s critPortRange: 'abc'.
	self presenter: (AbSettingsPresenter on: s).
	self presenter showsCritSettings: false.
	called := false.
	self presenter saveAction: [ called := true ].
	self assert: self presenter saveSettings.
	self assert: called
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testWindowIsShorterWhenCritSettingsAreHidden [
	| presenterWithoutCrit |
	presenterWithoutCrit := AbSettingsPresenter on: AbSettings new.
	presenterWithoutCrit showsCritSettings: false.
	self presenter open.
	presenterWithoutCrit open.
	[ self assert: presenterWithoutCrit window initialExtent y < self presenter window initialExtent y ]
		ensure: [
			self presenter window close.
			presenterWithoutCrit window close ]
]

{ #category : 'tests' }
AbSettingsPresenterTest >> testOpenOnTopicHidesCritSettings [
	| topicPresenter |
	topicPresenter := AbSettingsPresenter openOnTopic: self newMockTopic.
	[ self deny: topicPresenter showsCritSettings ] ensure: [ topicPresenter window close ]
]
