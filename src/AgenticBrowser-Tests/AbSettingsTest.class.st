Class {
	#name : 'AbSettingsTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSettingsTest >> setUp [

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
AbSettingsTest >> testDefaultCopiedDoesNotMutateDefault [

	| copied |
	copied := AbSettings defaultCopied.
	copied watcherMessageThrottleDuration: 5 seconds.
	self assert: AbSettings default watcherMessageThrottleDuration equals: 2 seconds
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
AbSettingsTest >> testUseDefaultMcpServersDefaultIsTrue [

	self assert: AbSettings default useDefaultMcpServers equals: true
]

{ #category : 'tests' }
AbSettingsTest >> testUseDefaultMcpServersSettable [

	| settings |
	settings := AbSettings defaultCopied.
	settings useDefaultMcpServers: false.
	self assert: settings useDefaultMcpServers equals: false
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleDurationDefault [

	self assert: AbSettings default watcherMessageThrottleDuration equals: 2 seconds
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleDurationSettable [

	AbSettings default watcherMessageThrottleDuration: 7 seconds.
	self assert: AbSettings default watcherMessageThrottleDuration equals: 7 seconds
]
