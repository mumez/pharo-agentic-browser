"
I am a settings editor that presents and saves an AbSettings instance.

Responsibility:
- I display all editable AbSettings fields: watcher throttle, AI permission timeout, export approval timeout, their timeout-option drop-lists, MCP server checkbox, goal-settings command fields, the initial prompt skill field with its st-buddy checkbox, the crit review checkbox, the crit LAN access checkbox, and the crit port range field.
- I rewrite the initial prompt skill field when the st-buddy checkbox is toggled (on: the AbSettings default skill, off: empty); editing the field does not change the checkbox, and on save only the field text is written.
- I validate the crit port range on save (reusing AbSettings>>critPortInterval); when it is invalid I write nothing, skip the saveAction, keep the window open, and show the expected format in a validation message label.
- I support two entry points: editing the global default settings (via #openOnDefault) and editing a per-topic copy (via #openOnTopic:).
- On save I invoke a configurable saveAction block; for the global path this writes ab-settings.json, for the topic path it replaces the topic's in-memory settings only.

Collaborators:
- AbSettings: I am the SpPresenterWithModel model; I read initial values from it and write back on save.
- AbBrowserPresenter: It opens me for global settings via the ""Settings..."" menu item.
- AbTopicListPresenter: It opens me for per-topic settings via the ""Edit Settings..."" context menu item.

Public API and Key Messages:
- AbSettingsPresenter class>>openOnDefault - Open editor for the global AbSettings singleton; saves to ab-settings.json on confirm.
- AbSettingsPresenter class>>openOnTopic: - Open editor for a topic's settings copy; replaces the topic's settings on confirm without a global save. The crit settings are hidden because crit reads only the global settings.
- #saveAction: - Inject a custom save block (receives the edited AbSettings as argument).
- #showsCritSettings: - Show or hide the crit review checkbox, network access checkbox, port range field, and validation message (shown by default); the window is shorter when they are hidden.

Internal Representation:
- saveAction - Block called with the edited AbSettings on save; defaults to a no-op.
- All field/widget instVars hold the Spec2 presenters for each individual setting.
- validationMessageLabel - Label that is empty normally and explains the expected crit port range format after an invalid save attempt.
- showsCritSettings - Whether the crit settings rows are laid out and the crit port range is checked on save.
"
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
		'useCommandOnGoalSetCheckbox',
		'goalSetCommandField',
		'initialPromptSkillField',
		'useStBuddySkillOnInitialPromptCheckbox',
		'useCritCheckbox',
		'critAllowUnauthenticatedNetworkCheckbox',
		'critPortRangeField',
		'validationMessageLabel',
		'showsCritSettings',
		'saveButton',
		'cancelButton'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'instance creation' }
AbSettingsPresenter class >> openOnDefault [
	| settingsCopy presenter |
	settingsCopy := AbSettings defaultCopied.
	presenter := self on: settingsCopy.
	presenter saveAction: [ :editedSettings |
		AbSettings default initFrom: editedSettings.
		AbSettings save ].
	presenter open.
	^ presenter
]

{ #category : 'instance creation' }
AbSettingsPresenter class >> openOnTopic: aTopic [
	| settingsCopy presenter |
	settingsCopy := AbSettings new initFrom: aTopic settings.
	presenter := self on: settingsCopy.
	presenter saveAction: [ :editedSettings |
		aTopic settings: editedSettings ].
	presenter showsCritSettings: false.
	presenter open.
	^ presenter
]

{ #category : 'accessing' }
AbSettingsPresenter >> settings [
	^ self model
]

{ #category : 'initialization' }
AbSettingsPresenter >> initialize [
	saveAction := [].
	showsCritSettings := true.
	super initialize
]

{ #category : 'accessing' }
AbSettingsPresenter >> saveAction: aBlock [
	saveAction := aBlock
]

{ #category : 'private' }
AbSettingsPresenter >> saveAction [
	^ saveAction
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
AbSettingsPresenter >> useCommandOnGoalSetCheckbox [
	^ useCommandOnGoalSetCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> initialPromptSkillField [
	^ initialPromptSkillField
]

{ #category : 'accessing' }
AbSettingsPresenter >> useStBuddySkillOnInitialPromptCheckbox [
	^ useStBuddySkillOnInitialPromptCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> goalSetCommandField [
	^ goalSetCommandField
]

{ #category : 'accessing' }
AbSettingsPresenter >> useCritCheckbox [
	^ useCritCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> critAllowUnauthenticatedNetworkCheckbox [
	^ critAllowUnauthenticatedNetworkCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> critPortRangeField [
	^ critPortRangeField
]

{ #category : 'accessing' }
AbSettingsPresenter >> validationMessageLabel [
	^ validationMessageLabel
]

{ #category : 'accessing' }
AbSettingsPresenter >> showsCritSettings [
	^ showsCritSettings
]

{ #category : 'accessing' }
AbSettingsPresenter >> showsCritSettings: aBoolean [
	showsCritSettings := aBoolean
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
	"Answer whether the settings were written; an invalid crit port range writes nothing and shows the expected format instead."
	self validateCritPortRange ifFalse: [ ^ false ].
	self settings watcherMessageThrottleSeconds: watcherThrottleField text asInteger.
	self settings aiPermissionWaitTimeoutSeconds: aiTimeoutField text asInteger.
	self settings exportApprovalWaitTimeoutSeconds: exportTimeoutField text asInteger.
	self settings aiPermissionTimeoutOption: (self optionIdForLabel: aiTimeoutOptionDropList selectedItem).
	self settings exportApprovalTimeoutOption: (self optionIdForLabel: exportTimeoutOptionDropList selectedItem).
	self settings useDefaultMcpServers: useDefaultMcpServersCheckbox state.
	self settings useCommandOnGoalSet: useCommandOnGoalSetCheckbox state.
	self settings goalSetCommand: goalSetCommandField text.
	self settings initialPromptSkill: initialPromptSkillField text.
	self settings useCrit: self useCritCheckbox state.
	self settings critAllowUnauthenticatedNetwork: self critAllowUnauthenticatedNetworkCheckbox state.
	self settings critPortRange: self critPortRangeField text.
	self saveAction cull: self settings.
	^ true
]

{ #category : 'private' }
AbSettingsPresenter >> validateCritPortRange [
	"Answer whether the crit port range can be saved, showing the expected format in the validation message when it cannot. The range is not checked when the crit settings are hidden."
	(self showsCritSettings and: [ self isCritPortRangeValid not ]) ifTrue: [
		self validationMessageLabel label: 'Crit port range must look like ' , self settings defaultCritPortRange , ' (1-65535).'.
		^ false ].
	self validationMessageLabel label: ''.
	^ true
]

{ #category : 'private' }
AbSettingsPresenter >> isCritPortRangeValid [
	^ (AbSettings new
		   critPortRange: self critPortRangeField text;
		   critPortInterval) notNil
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
AbSettingsPresenter >> newApprovalOptionDropListFor: anOptionSymbol [
	| dl |
	dl := self newDropList.
	dl items: self approvalOptionLabels.
	dl selectItem: (self labelForOptionId: anOptionSymbol).
	^ dl
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

	aiTimeoutOptionDropList := self newApprovalOptionDropListFor: self settings aiPermissionTimeoutOption.
	exportTimeoutOptionDropList := self newApprovalOptionDropListFor: self settings exportApprovalTimeoutOption.

	useDefaultMcpServersCheckbox := self newCheckBox.
	useDefaultMcpServersCheckbox label: 'Use default MCP servers'.
	useDefaultMcpServersCheckbox state: self settings useDefaultMcpServers.

	useCommandOnGoalSetCheckbox := self newCheckBox.
	useCommandOnGoalSetCheckbox label: 'Use command on goal settings'.
	useCommandOnGoalSetCheckbox state: self settings useCommandOnGoalSet.

	goalSetCommandField := self newTextInput.
	goalSetCommandField text: self settings goalSetCommand.

	useStBuddySkillOnInitialPromptCheckbox := self newCheckBox.
	useStBuddySkillOnInitialPromptCheckbox label: 'Use st-buddy skill on initial prompt'.
	useStBuddySkillOnInitialPromptCheckbox state: self settings useStBuddySkillOnInitialPrompt.
	useStBuddySkillOnInitialPromptCheckbox whenChangedDo: [ :useStBuddySkill |
		self updateInitialPromptSkillFieldForUseStBuddySkill: useStBuddySkill ].

	initialPromptSkillField := self newTextInput.
	initialPromptSkillField text: self settings initialPromptSkill.

	self initializeCritSettingsPresenters.

	saveButton := self newButton.
	saveButton label: 'Save'.
	saveButton action: [ self saveSettings ifTrue: [ self window close ] ].

	cancelButton := self newButton.
	cancelButton label: 'Cancel'.
	cancelButton action: [ self window close ]
]

{ #category : 'private' }
AbSettingsPresenter >> updateInitialPromptSkillFieldForUseStBuddySkill: aBoolean [
	self initialPromptSkillField text: (aBoolean
			 ifTrue: [ self settings defaultInitialPromptSkill ]
			 ifFalse: [ '' ])
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializeCritSettingsPresenters [
	useCritCheckbox := self newCheckBox.
	useCritCheckbox label: 'Use crit review'.
	useCritCheckbox state: self settings useCrit.

	critAllowUnauthenticatedNetworkCheckbox := self newCheckBox.
	critAllowUnauthenticatedNetworkCheckbox label: 'Allow crit access within LAN (other than localhost)'.
	critAllowUnauthenticatedNetworkCheckbox state: self settings critAllowUnauthenticatedNetwork.

	critPortRangeField := self newTextInput.
	critPortRangeField text: self settings critPortRange.

	validationMessageLabel := self newLabel.
	validationMessageLabel label: ''
]

{ #category : 'layout' }
AbSettingsPresenter >> defaultLayout [
	| layout |
	layout := SpBoxLayout newTopToBottom
		borderWidth: 10;
		spacing: 6;
		yourself.
	self addGeneralSettingsTo: layout.
	self showsCritSettings ifTrue: [ self addCritSettingsTo: layout ].
	^ layout
		addLast: self actionButtonsLayout withConstraints: [ :c | c height: 34 ];
		yourself
]

{ #category : 'layout' }
AbSettingsPresenter >> addGeneralSettingsTo: aBoxLayout [
	aBoxLayout
		add: (self labeledRow: 'Watcher throttle (seconds):' field: self watcherThrottleField);
		add: (self labeledRow: 'AI permission timeout (seconds):' field: self aiTimeoutField);
		add: (self labeledRow: 'AI timeout option:' field: self aiTimeoutOptionDropList);
		add: (self labeledRow: 'Export timeout (seconds):' field: self exportTimeoutField);
		add: (self labeledRow: 'Export timeout option:' field: self exportTimeoutOptionDropList);
		add: self useDefaultMcpServersCheckbox withConstraints: [ :c | c height: 28 ];
		add: self useCommandOnGoalSetCheckbox withConstraints: [ :c | c height: 28 ];
		add: (self labeledRow: 'Goal settings command:' field: self goalSetCommandField);
		add: (self labeledRow: 'Initial Prompt Skill:' field: self initialPromptSkillField);
		add: self useStBuddySkillOnInitialPromptCheckbox withConstraints: [ :c | c height: 28 ]
]

{ #category : 'layout' }
AbSettingsPresenter >> addCritSettingsTo: aBoxLayout [
	aBoxLayout
		add: self useCritCheckbox withConstraints: [ :c | c height: 28 ];
		add: self critAllowUnauthenticatedNetworkCheckbox withConstraints: [ :c | c height: 28 ];
		add: (self labeledRow: 'Crit port range:' field: self critPortRangeField);
		add: self validationMessageLabel withConstraints: [ :c | c height: 20 ]
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
	"The leading expanding spacer keeps the row's width calculation stable on Pharo 14, where a row of only fixed-width buttons overflows past the window edge."
	^ SpBoxLayout newLeftToRight
		add: (self newLabel label: '') expand: true;
		add: saveButton withConstraints: [ :c | c width: 80; height: 34 ];
		add: cancelButton withConstraints: [ :c | c width: 80; height: 34 ];
		yourself
]

{ #category : 'initialization' }
AbSettingsPresenter >> initializeWindow: aWindowPresenter [
	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Settings';
		initialExtent: 420 @ self windowHeight
]

{ #category : 'private' }
AbSettingsPresenter >> windowHeight [
	"Shrink the window when the crit rows are hidden so the remaining rows do not stretch to fill it."
	^ self showsCritSettings
		ifTrue: [ 584 ]
		ifFalse: [ 454 ]
]
