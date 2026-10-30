Class {
	#name : 'AbSettingsTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSettingsTest >> setUp [

	super setUp.

	AbSettings initialize
]

{ #category : 'tests' }
AbSettingsTest >> testAiPermissionWaitTimeoutSecondsDefault [

	self assert: AbSettings default aiPermissionWaitTimeoutSeconds equals: 1800
]

{ #category : 'tests' }
AbSettingsTest >> testAiPermissionWaitTimeoutSecondsSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings aiPermissionWaitTimeoutSeconds: 120.
	self assert: settings aiPermissionWaitTimeoutSeconds equals: 120
]

{ #category : 'tests' }
AbSettingsTest >> testAiPermissionTimeoutOptionDefault [

	self assert: AbSettings default aiPermissionTimeoutOption equals: AbConstants rejectOnce
]

{ #category : 'tests' }
AbSettingsTest >> testAiPermissionTimeoutOptionSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings aiPermissionTimeoutOption: AbConstants allowAlways.
	self assert: settings aiPermissionTimeoutOption equals: AbConstants allowAlways
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCopiedDoesNotMutateDefault [

	| copied |
	copied := AbSettings defaultCopied.
	copied watcherMessageThrottleSeconds: 5.
	self assert: AbSettings default watcherMessageThrottleSeconds equals: 2
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultReturnsSingletonInstance [

	self assert: AbSettings default == AbSettings default
]

{ #category : 'tests' }
AbSettingsTest >> testExportApprovalWaitTimeoutSecondsDefault [

	self assert: AbSettings default exportApprovalWaitTimeoutSeconds equals: 30
]

{ #category : 'tests' }
AbSettingsTest >> testExportApprovalWaitTimeoutSecondsSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings exportApprovalWaitTimeoutSeconds: 60.
	self assert: settings exportApprovalWaitTimeoutSeconds equals: 60
]

{ #category : 'tests' }
AbSettingsTest >> testExportApprovalTimeoutOptionDefault [

	self assert: AbSettings default exportApprovalTimeoutOption equals: AbConstants rejectOnce
]

{ #category : 'tests' }
AbSettingsTest >> testExportApprovalTimeoutOptionSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings exportApprovalTimeoutOption: AbConstants allowAlways.
	self assert: settings exportApprovalTimeoutOption equals: AbConstants allowAlways
]

{ #category : 'tests' }
AbSettingsTest >> testUseDefaultMcpServersDefaultIsTrue [

	self assert: AbSettings default useDefaultMcpServers
]

{ #category : 'tests' }
AbSettingsTest >> testUseDefaultMcpServersSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings useDefaultMcpServers: false.
	self assert: settings useDefaultMcpServers equals: false
]

{ #category : 'tests' }
AbSettingsTest >> testMaxAttachmentSizeDefault [

	self assert: AbSettings default maxAttachmentSize equals: 5 * 1024 * 1024
]

{ #category : 'tests' }
AbSettingsTest >> testMaxAttachmentSizeSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings maxAttachmentSize: 5000.
	self assert: settings maxAttachmentSize equals: 5000
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleSecondsDefault [

	self assert: AbSettings default watcherMessageThrottleSeconds equals: 2
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleSecondsSettable [

	AbSettings default watcherMessageThrottleSeconds: 7.
	self assert: AbSettings default watcherMessageThrottleSeconds equals: 7
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleDurationDerivedFromSeconds [

	AbSettings default watcherMessageThrottleSeconds: 5.
	self assert: AbSettings default watcherMessageThrottleDuration equals: 5 seconds
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCopiedUnsetValueFallsBackToDefault [

	| copied |
	copied := AbSettings defaultCopied.
	self assert: copied exportApprovalWaitTimeoutSeconds equals: AbSettings default exportApprovalWaitTimeoutSeconds
]

{ #category : 'tests' }
AbSettingsTest >> testReadingValueDoesNotModifySettingsDict [

	| settings |
	settings := AbSettings new.
	settings exportApprovalWaitTimeoutSeconds.
	self assert: settings keys isEmpty
]

{ #category : 'tests' }
AbSettingsTest >> testAsFullJsonDictionaryContainsAllAccessingKeys [

	| dict |
	dict := AbSettings default asFullJsonDictionary.
	self assert: (dict includesKey: 'exportApprovalWaitTimeoutSeconds').
	self assert: (dict includesKey: 'aiPermissionWaitTimeoutSeconds').
	self assert: (dict includesKey: 'exportApprovalTimeoutOption').
	self assert: (dict includesKey: 'aiPermissionTimeoutOption').
	self assert: (dict includesKey: 'useDefaultMcpServers').
	self assert: (dict includesKey: 'watcherMessageThrottleSeconds').
	self assert: (dict includesKey: 'codingAgents').
	self assert: (dict includesKey: 'goalSetCommand').
	self assert: (dict includesKey: 'useCommandOnGoalSet').
	self assert: (dict includesKey: 'initialPromptSkill').
	self assert: (dict includesKey: 'goalHavingTopicStallThresholdSeconds').
	self assert: (dict includesKey: 'monitoringIntervalSeconds').
	self assert: (dict includesKey: 'useCrit').
	self assert: (dict includesKey: 'critPortRange').
	self assert: (dict includesKey: 'critAllowUnauthenticatedNetwork').
	self deny: (dict includesKey: 'watcherMessageThrottleDuration').
	self deny: (dict includesKey: 'stallMonitoringIntervalSeconds').
	self deny: (dict includesKey: 'critPortInterval').
	self deny: (dict includesKey: 'useStBuddySkillOnInitialPrompt')
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCodingAgentsIsNotEmpty [

	self assert: AbSettings default codingAgents notEmpty
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCodingAgentsContainsClaudeAgentAcp [

	| agents |
	agents := AbSettings default codingAgents.
	self assert: (agents anySatisfy: [ :each | (each at: 'name') = 'claude-agent-acp' ])
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultAgentArgumentsPresetsContainsGrokBuild [

	self
		assert: (AbSettings default agentArgumentsPresets at: 'Grok Build')
		equals: #( 'grok' 'agent' 'stdio' )
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCodingAgentsEachHasNameAndCommand [

	AbSettings default codingAgents do: [ :each |
		self assert: (each includesKey: 'name').
		self assert: (each includesKey: 'command') ]
]

{ #category : 'tests' }
AbSettingsTest >> testCodingAgentsSettable [

	| settings custom |
	settings := AbSettings defaultCopied.
	custom := { Dictionary new at: 'name' put: 'my-agent'; at: 'command' put: #('my-agent'); yourself }.
	settings codingAgents: custom.
	self assert: ((settings codingAgents first) at: 'name') equals: 'my-agent'
]

{ #category : 'tests' }
AbSettingsTest >> testGoalSetCommandDefaultIsGoal [

	self assert: AbSettings default goalSetCommand equals: '/goal'
]

{ #category : 'tests' }
AbSettingsTest >> testGoalSetCommandSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings goalSetCommand: '/mygoal'.
	self assert: settings goalSetCommand equals: '/mygoal'
]

{ #category : 'tests' }
AbSettingsTest >> testUseCommandOnGoalSetDefaultIsFalse [

	self assert: AbSettings default useCommandOnGoalSet equals: false
]

{ #category : 'tests' }
AbSettingsTest >> testUseCommandOnGoalSetSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings useCommandOnGoalSet: true.
	self assert: settings useCommandOnGoalSet equals: true
]

{ #category : 'tests' }
AbSettingsTest >> testInitialPromptSkillDefaultIsStBuddy [

	self assert: AbSettings default initialPromptSkill equals: '/smalltalk-dev:st-buddy'
]

{ #category : 'tests' }
AbSettingsTest >> testInitialPromptSkillSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings initialPromptSkill: '$st-buddy'.
	self assert: settings initialPromptSkill equals: '$st-buddy'
]

{ #category : 'tests' }
AbSettingsTest >> testInitialPromptSkillSetterTreatsNilAsEmpty [

	| settings |
	settings := AbSettings defaultCopied.
	settings initialPromptSkill: nil.
	self assert: settings initialPromptSkill equals: ''.
	self deny: settings useStBuddySkillOnInitialPrompt
]

{ #category : 'tests' }
AbSettingsTest >> testInitialPromptSkillSetterTrimsSurroundingSpaces [

	| settings |
	settings := AbSettings defaultCopied.
	settings initialPromptSkill: ' $st-buddy '.
	self assert: settings initialPromptSkill equals: '$st-buddy'
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptDefaultIsTrue [

	self assert: AbSettings default useStBuddySkillOnInitialPrompt
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptTrueSetsDefaultInitialPromptSkill [

	| settings |
	settings := AbSettings defaultCopied.
	settings initialPromptSkill: '$st-buddy'.
	settings useStBuddySkillOnInitialPrompt: true.
	self assert: settings initialPromptSkill equals: '/smalltalk-dev:st-buddy'
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptFalseClearsInitialPromptSkill [

	| settings |
	settings := AbSettings defaultCopied.
	settings useStBuddySkillOnInitialPrompt: false.
	self assert: settings initialPromptSkill equals: ''.
	self deny: settings useStBuddySkillOnInitialPrompt
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptSetterDoesNotStoreOwnKey [

	| settings |
	settings := AbSettings new.
	settings useStBuddySkillOnInitialPrompt: true.
	self deny: (settings keys includes: #useStBuddySkillOnInitialPrompt)
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptIsTrueForStBuddySkills [

	| settings |
	settings := AbSettings defaultCopied.
	#( '/st-buddy' '/smalltalk-dev:st-buddy' '$st-buddy' '$smalltalk-dev:st-buddy' ' /smalltalk-dev:st-buddy ' )
		do: [ :each |
			settings initialPromptSkill: each.
			self assert: settings useStBuddySkillOnInitialPrompt ]
]

{ #category : 'tests' }
AbSettingsTest >> testUseStBuddySkillOnInitialPromptIsFalseForOtherSkills [

	| settings |
	settings := AbSettings defaultCopied.
	#( '$other-skill' 'st-buddy' '/st-buddy extra' '' ) do: [ :each |
		settings initialPromptSkill: each.
		self deny: settings useStBuddySkillOnInitialPrompt ]
]

{ #category : 'tests' }
AbSettingsTest >> testLoadFromAcceptsOldUseStBuddySkillOnInitialPromptTrue [

	| file settings |
	file := FileSystem memory root / 'ab-settings.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: '{"useStBuddySkillOnInitialPrompt": true}' ].
	settings := AbSettings loadFrom: file.
	self assert: settings initialPromptSkill equals: '/smalltalk-dev:st-buddy'
]

{ #category : 'tests' }
AbSettingsTest >> testLoadFromAcceptsOldUseStBuddySkillOnInitialPromptFalse [

	| file settings |
	file := FileSystem memory root / 'ab-settings.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: '{"useStBuddySkillOnInitialPrompt": false}' ].
	settings := AbSettings loadFrom: file.
	self assert: settings initialPromptSkill equals: ''
]

{ #category : 'tests' }
AbSettingsTest >> testGoalHavingTopicStallThresholdSecondsDefault [

	self assert: AbSettings default goalHavingTopicStallThresholdSeconds equals: 120
]

{ #category : 'tests' }
AbSettingsTest >> testGoalHavingTopicStallThresholdSecondsSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings goalHavingTopicStallThresholdSeconds: 60.
	self assert: settings goalHavingTopicStallThresholdSeconds equals: 60
]

{ #category : 'tests' }
AbSettingsTest >> testMonitoringIntervalSecondsDefault [

	self assert: AbSettings default monitoringIntervalSeconds equals: 15
]

{ #category : 'tests' }
AbSettingsTest >> testMonitoringIntervalSecondsSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings monitoringIntervalSeconds: 45.
	self assert: settings monitoringIntervalSeconds equals: 45
]

{ #category : 'tests' }
AbSettingsTest >> testLoadFromAcceptsOldStallMonitoringIntervalSecondsKey [

	| file settings |
	file := FileSystem memory root / 'ab-settings.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: '{"stallMonitoringIntervalSeconds": 45}' ].
	settings := AbSettings loadFrom: file.
	self assert: settings monitoringIntervalSeconds equals: 45
]

{ #category : 'tests' }
AbSettingsTest >> testSaveAfterLoadingOldIntervalKeyWritesOnlyNewKey [

	| file saved dict |
	file := FileSystem memory root / 'ab-settings.json'.
	file writeStreamDo: [ :stream | stream nextPutAll: '{"stallMonitoringIntervalSeconds": 45}' ].
	saved := file parent / 'saved.json'.
	(AbSettings loadFrom: file) saveFullTo: saved.
	dict := STONJSON fromString: saved contents.
	self assert: (dict at: 'monitoringIntervalSeconds') equals: 45.
	self deny: (dict includesKey: 'stallMonitoringIntervalSeconds')
]

{ #category : 'tests' }
AbSettingsTest >> testSaveFullToReplacesExistingLongerFileCompletely [

	| settings dict |
	self withTempDirectoryDo: [ :root |
		| file |
		file := root / 'ab-settings.json'.
		self writeLongerFile: file marked: 'TRAILING-OLD-CONTENT'.
		settings := AbSettings new.
		settings monitoringIntervalSeconds: 15.
		settings saveFullTo: file.
		self deny: (file contents includesSubstring: 'TRAILING-OLD-CONTENT').
		dict := STONJSON fromString: file contents.
		self assert: (dict at: 'monitoringIntervalSeconds') equals: 15 ]
]

{ #category : 'tests' }
AbSettingsTest >> testSaveFullToRestoresExistingFileWhenWritingFails [

	| settings original |
	original := '{"monitoringIntervalSeconds": 30}'.
	self withTempDirectoryDo: [ :root |
		| file |
		file := root / 'ab-settings.json'.
		file writeStreamDo: [ :stream | stream nextPutAll: original ].
		settings := AbSettings new.
		"An empty block is not JSON, so serialization fails inside the write."
		settings monitoringIntervalSeconds: [].
		self should: [ settings saveFullTo: file ] raise: Error.
		self assert: file exists.
		self assert: file contents equals: original ]
]

{ #category : 'tests' }
AbSettingsTest >> testUseCritDefaultIsFalse [

	self deny: AbSettings default useCrit
]

{ #category : 'tests' }
AbSettingsTest >> testUseCritSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings useCrit: true.
	self assert: settings useCrit
]

{ #category : 'tests' }
AbSettingsTest >> testCritPortRangeDefault [

	self assert: AbSettings default critPortRange equals: '9080-9100'
]

{ #category : 'tests' }
AbSettingsTest >> testCritPortRangeSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings critPortRange: '9100-9110'.
	self assert: settings critPortRange equals: '9100-9110'
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCopiedUnsetCritSettingsFallBackToDefault [

	| copied |
	AbSettings default useCrit: true.
	AbSettings default critPortRange: '9101-9102'.
	copied := AbSettings defaultCopied.
	self assert: copied useCrit.
	self assert: copied critPortRange equals: '9101-9102'
]

{ #category : 'tests' }
AbSettingsTest >> testCritAllowUnauthenticatedNetworkDefaultIsTrue [

	self assert: AbSettings default critAllowUnauthenticatedNetwork
]

{ #category : 'tests' }
AbSettingsTest >> testCritAllowUnauthenticatedNetworkSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings critAllowUnauthenticatedNetwork: false.
	self deny: settings critAllowUnauthenticatedNetwork
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCopiedUnsetCritAllowUnauthenticatedNetworkFallsBackToDefault [

	AbSettings default critAllowUnauthenticatedNetwork: false.
	self deny: AbSettings defaultCopied critAllowUnauthenticatedNetwork
]

{ #category : 'tests' }
AbSettingsTest >> testCritAllowUnauthenticatedNetworkSurvivesSaveAndLoad [

	| file settings loaded |
	file := FileSystem memory root / 'ab-settings.json'.
	settings := AbSettings new.
	settings critAllowUnauthenticatedNetwork: false.
	settings saveFullTo: file.
	loaded := AbSettings loadFrom: file.
	self deny: loaded critAllowUnauthenticatedNetwork
]

{ #category : 'tests' }
AbSettingsTest >> testCritPortIntervalParsesInclusiveRange [

	AbSettings default critPortRange: '9080-9100'.
	self assert: AbSettings default critPortInterval equals: (9080 to: 9100)
]

{ #category : 'tests' }
AbSettingsTest >> testCritPortIntervalAcceptsSinglePort [

	AbSettings default critPortRange: '9080-9080'.
	self assert: AbSettings default critPortInterval equals: (9080 to: 9080)
]

{ #category : 'tests' }
AbSettingsTest >> testCritPortIntervalRejectsMalformedOrOutOfBoundsRanges [

	#( 'abc' '9080' '9080-' '-9100' ' 9080-9100' '9080-9100 ' '9080-9100-1' '' '0-9100' '9080-65536' '9100-9080' '0-0' ) do: [ :each |
		AbSettings default critPortRange: each.
		self assert: AbSettings default critPortInterval isNil ]
]

{ #category : 'tests' }
AbSettingsTest >> testCritSettingsSurviveSaveAndLoad [

	| file settings loaded |
	file := FileSystem memory root / 'ab-settings.json'.
	settings := AbSettings new.
	settings useCrit: true.
	settings critPortRange: '9200-9210'.
	settings saveFullTo: file.
	loaded := AbSettings loadFrom: file.
	self assert: loaded useCrit.
	self assert: loaded critPortRange equals: '9200-9210'
]
