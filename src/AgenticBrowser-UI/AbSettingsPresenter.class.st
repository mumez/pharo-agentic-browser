"
I am a settings editor that presents and saves an AbSettings instance.

Responsibility:
- I display all editable AbSettings fields: watcher throttle, AI permission timeout, export approval timeout, their timeout-option drop-lists, MCP server checkbox, and goal-settings command fields.
- I support two entry points: editing the global default settings (via #openOnDefault) and editing a per-topic copy (via #openOnTopic:).
- On save I invoke a configurable saveAction block; for the global path this writes the fuel file, for the topic path it replaces the topic's in-memory settings only.

Collaborators:
- AbSettings: I am the SpPresenterWithModel model; I read initial values from it and write back on save.
- AbBrowserPresenter: It opens me for global settings via the ""Settings..."" menu item.
- AbTopicListPresenter: It opens me for per-topic settings via the ""Edit Settings..."" context menu item.

Public API and Key Messages:
- AbSettingsPresenter class>>openOnDefault - Open editor for the global AbSettings singleton; saves to fuel on confirm.
- AbSettingsPresenter class>>openOnTopic: - Open editor for a topic's settings copy; replaces the topic's settings on confirm without a global save.
- #saveAction: - Inject a custom save block (receives the edited AbSettings as argument).

Internal Representation:
- saveAction - Block called with the edited AbSettings on save; defaults to a no-op.
- All field/widget instVars hold the Spec2 presenters for each individual setting.
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
		'useStBuddySkillOnInitialPromptCheckbox',
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
AbSettingsPresenter >> useStBuddySkillOnInitialPromptCheckbox [
	^ useStBuddySkillOnInitialPromptCheckbox
]

{ #category : 'accessing' }
AbSettingsPresenter >> goalSetCommandField [
	^ goalSetCommandField
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
	self settings useCommandOnGoalSet: useCommandOnGoalSetCheckbox state.
	self settings goalSetCommand: goalSetCommandField text.
	self settings useStBuddySkillOnInitialPrompt: useStBuddySkillOnInitialPromptCheckbox state.
	self saveAction cull: self settings
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
		add: useCommandOnGoalSetCheckbox withConstraints: [ :c | c height: 28 ];
		add: (self labeledRow: 'Goal settings command:' field: goalSetCommandField);
		add: useStBuddySkillOnInitialPromptCheckbox withConstraints: [ :c | c height: 28 ];
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
		initialExtent: 420 @ 420
]
