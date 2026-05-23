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
	self deny: (dict includesKey: 'watcherMessageThrottleDuration')
]
