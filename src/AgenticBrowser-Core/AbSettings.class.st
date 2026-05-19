Class {
	#name : 'AbSettings',
	#superclass : 'Object',
	#instVars : [
		'settingsDict'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbSettings class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'persistence' }
AbSettings class >> defaultAgenticBrowserRootDirectory [

	^ Smalltalk imageDirectory / 'agentic-browser'
]

{ #category : 'instance creation' }
AbSettings class >> defaultCopied [

	^ self new initFrom: self default
]

{ #category : 'persistence' }
AbSettings class >> defaultFileReference [

	^ self defaultAgenticBrowserRootDirectory / self fileName
]

{ #category : 'persistence' }
AbSettings class >> fileName [

	^ 'ab-settings.ston'
]

{ #category : 'class initialization' }
AbSettings class >> initialize [

	default := nil
]

{ #category : 'persistence' }
AbSettings class >> load [

	self defaultFileReference exists ifFalse: [ ^ self ].
	default := self loadFrom: self defaultFileReference
]

{ #category : 'persistence' }
AbSettings class >> loadFrom: aFileReference [

	| dict settings |
	dict := aFileReference readStreamDo: [ :stream | STON fromStream: stream ].
	settings := self new.
	dict keysAndValuesDo: [ :k :v | settings at: k put: v ].
	^ settings
]

{ #category : 'persistence' }
AbSettings class >> save [

	self saveTo: self defaultFileReference
]

{ #category : 'persistence' }
AbSettings class >> saveTo: aFileReference [

	self default saveFullTo: aFileReference
]

{ #category : 'persistence' }
AbSettings >> saveFullTo: aFileReference [

	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream |
		(STONWriter on: stream)
			prettyPrint: true;
			nextPut: self asFullStonDictionary ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds [

	^ self
		  at: #aiPermissionWaitTimeoutSeconds
		  ifAbsent: [ self defaultAiPermissionWaitTimeoutSeconds ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds: anInteger [

	self at: #aiPermissionWaitTimeoutSeconds put: anInteger
]

{ #category : 'converting' }
AbSettings >> asFullStonDictionary [
	| selectors |
	selectors := (self class selectorsInProtocol: 'accessing') select: [ :each | each isUnary ].
	^ selectors inject: Dictionary new into: [:dic :each |
		dic at: each asString put: (self perform: each).
		dic
	]
]

{ #category : 'actions-dictionary' }
AbSettings >> at: aKey ifAbsentPut: aBlock [

	^ self settingsDict at: aKey ifAbsentPut: aBlock
]

{ #category : 'actions-dictionary' }
AbSettings >> at: aKey put: aValue [

	^ self settingsDict at: aKey put: aValue
]

{ #category : 'defaults' }
AbSettings >> defaultAiPermissionWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultAiPermissionWaitTimeoutSeconds ].
	^ 1800
]

{ #category : 'defaults' }
AbSettings >> defaultExportApprovalWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultExportApprovalWaitTimeoutSeconds ].
	^ 30
]

{ #category : 'defaults' }
AbSettings >> defaultUseDefaultMcpServers [
	self isDefault ifFalse: [ ^ self class default defaultUseDefaultMcpServers ].
	^ true
]

{ #category : 'defaults' }
AbSettings >> defaultWatcherMessageThrottleDuration [
	self isDefault ifFalse: [ ^ self class default defaultWatcherMessageThrottleDuration ].
	^ 2 seconds
]

{ #category : 'accessing' }
AbSettings >> exportApprovalWaitTimeoutSeconds [

	^ self
		  at: #exportApprovalWaitTimeoutSeconds
		  ifAbsent: [ self defaultExportApprovalWaitTimeoutSeconds ]
]

{ #category : 'accessing' }
AbSettings >> exportApprovalWaitTimeoutSeconds: anInteger [

	self at: #exportApprovalWaitTimeoutSeconds put: anInteger
]

{ #category : 'initialization' }
AbSettings >> initFrom: otherSettings [

	self initialize.
	otherSettings settingsDict keysAndValuesDo: [ :k :v |
		self settingsDict at: k put: v ].
	^ self
]

{ #category : 'initialization' }
AbSettings >> initialize [

	settingsDict := Dictionary new
]

{ #category : 'actions-dictionary' }
AbSettings >> keys [

	^ self settingsDict keys
]

{ #category : 'private' }
AbSettings >> settingsDict [

	^ settingsDict
]

{ #category : 'testing' }
AbSettings >> isDefault [

	^ self == self class default
]

{ #category : 'accessing' }
AbSettings >> useDefaultMcpServers [

	^ self
		  at: #useDefaultMcpServers
		  ifAbsent: [ self defaultUseDefaultMcpServers ]
]

{ #category : 'accessing' }
AbSettings >> useDefaultMcpServers: aBoolean [

	self at: #useDefaultMcpServers put: aBoolean
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration [

	^ self
		  at: #watcherMessageThrottleDuration
		  ifAbsent: [ self defaultWatcherMessageThrottleDuration ]
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration: aDuration [

	self at: #watcherMessageThrottleDuration put: aDuration
]
