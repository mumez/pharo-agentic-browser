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

	^ 'ab-settings.json'
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
	dict := STONJSON fromString: aFileReference contents.
	settings := self new.
	dict keysAndValuesDo: [ :k :v | settings perform: k asSymbol asMutator with: v ].
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
		stream nextPutAll: (STONJSON toStringPretty: self asFullJsonDictionary) ]
]

{ #category : 'accessing' }
AbSettings >> codingAgents [

	^ self at: #codingAgents ifAbsent: [ self defaultCodingAgents ]
]

{ #category : 'accessing' }
AbSettings >> codingAgents: anArray [

	self at: #codingAgents put: anArray
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds [

	^ self
		  at: #aiPermissionWaitTimeoutSeconds
		  ifAbsent: [ self defaultAiPermissionWaitTimeoutSeconds ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionTimeoutOption [

	^ self
		  at: #aiPermissionTimeoutOption
		  ifAbsent: [ self defaultAiPermissionTimeoutOption ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionTimeoutOption: anOption [

	self at: #aiPermissionTimeoutOption put: (anOption ifNotNil: [ anOption asSymbol ])
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds: anInteger [

	self at: #aiPermissionWaitTimeoutSeconds put: anInteger
]

{ #category : 'converting' }
AbSettings >> asFullJsonDictionary [
	| selectors |
	selectors := (self class selectorsInProtocol: 'accessing') select: [ :each | each isUnary ].
	^ selectors inject: Dictionary new into: [:dic :each |
		dic at: each asString put: (self perform: each).
		dic
	]
]

{ #category : 'actions-dictionary' }
AbSettings >> at: aKey ifAbsent: aBlock [

	^ self settingsDict at: aKey ifAbsent: aBlock
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
AbSettings >> defaultCodingAgents [
	self isDefault ifFalse: [ ^ self class default defaultCodingAgents ].
	^ STONJSON fromString: self defaultCodingAgentsJsonString
]

{ #category : 'defaults' }
AbSettings >> defaultCodingAgentsJsonString [
	^ '
[
  {"name": "claude-agent-acp", "command": ["claude-agent-acp"]},
  {"name": "Gemini CLI", "command": ["gemini", "--acp"]},
  {"name": "OpenCode", "command": ["opencode", "acp"]},
  {"name": "Copilot CLI", "command": ["copilot", "--acp", "--stdio"]},
  {"name": "codex-acp", "command": ["codex-acp"]}
]
'
]

{ #category : 'defaults' }
AbSettings >> defaultAiPermissionTimeoutOption [
	self isDefault ifFalse: [ ^ self class default defaultAiPermissionTimeoutOption ].
	^ AbConstants rejectOnce
]

{ #category : 'defaults' }
AbSettings >> defaultExportApprovalWaitTimeoutSeconds [
	self isDefault ifFalse: [ ^ self class default defaultExportApprovalWaitTimeoutSeconds ].
	^ 30
]

{ #category : 'defaults' }
AbSettings >> defaultExportApprovalTimeoutOption [
	self isDefault ifFalse: [ ^ self class default defaultExportApprovalTimeoutOption ].
	^ AbConstants rejectOnce
]

{ #category : 'defaults' }
AbSettings >> defaultUseDefaultMcpServers [
	self isDefault ifFalse: [ ^ self class default defaultUseDefaultMcpServers ].
	^ true
]

{ #category : 'defaults' }
AbSettings >> defaultWatcherMessageThrottleSeconds [
	self isDefault ifFalse: [ ^ self class default defaultWatcherMessageThrottleSeconds ].
	^ 2
]

{ #category : 'accessing' }
AbSettings >> exportApprovalWaitTimeoutSeconds [

	^ self
		  at: #exportApprovalWaitTimeoutSeconds
		  ifAbsent: [ self defaultExportApprovalWaitTimeoutSeconds ]
]

{ #category : 'accessing' }
AbSettings >> exportApprovalTimeoutOption [

	^ self
		  at: #exportApprovalTimeoutOption
		  ifAbsent: [ self defaultExportApprovalTimeoutOption ]
]

{ #category : 'accessing' }
AbSettings >> exportApprovalTimeoutOption: anOption [

	self at: #exportApprovalTimeoutOption put: (anOption ifNotNil: [ anOption asSymbol ])
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
AbSettings >> watcherMessageThrottleSeconds [

	^ self
		  at: #watcherMessageThrottleSeconds
		  ifAbsent: [ self defaultWatcherMessageThrottleSeconds ]
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleSeconds: anInteger [

	self at: #watcherMessageThrottleSeconds put: anInteger
]

{ #category : 'accessing-convenient' }
AbSettings >> watcherMessageThrottleDuration [

	^ self watcherMessageThrottleSeconds seconds
]
