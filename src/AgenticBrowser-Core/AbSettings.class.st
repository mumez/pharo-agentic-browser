"
I hold configuration for AgenticBrowser with a two-level hierarchy: a global singleton and per-topic copies.

Responsibility:
- I store timeout durations and options for AI permission and package export approvals.
- I cap how many characters of a file attachment's contents are embedded into a prompt via #maxAttachmentSize.
- I control whether built-in Smalltalk MCP servers are merged into the agent's MCP config.
- I persist the list of available coding agents shown in the New Topic dialog.
- I load from and save to ab-settings.json using STON/JSON serialization.
- I delegate defaults to the global instance when I am a non-default (per-topic) copy.

Collaborators:
- AbTopic: It holds a per-topic copy created via AbSettings class>>defaultCopied.
- AbMcpServersLoader: It reads #useDefaultMcpServers to decide whether to merge built-in servers.
- AbTopicRelatedPackagesWatcher: It reads #watcherMessageThrottleDuration for throttle control.
- AbTopicGoal: It reads #useCommandOnGoalSet and #goalSetCommand.
- AbFileAttachment: It reads #maxAttachmentSize from the global default to truncate prompt content.

Public API and Key Messages:
- AbSettings class>>default - Global singleton; created lazily.
- AbSettings class>>defaultCopied - Creates a fresh copy of the global settings for per-topic use.
- AbSettings class>>load / #save - Load from / save to ab-settings.json.
- #initFrom: - Copy all keys from another settings instance into self.

Internal Representation:
- settingsDict - Dictionary keyed by Symbol storing all explicitly set values.
- default (class inst var) - Cached global singleton; reset on class initialize.

Implementation Points:
- Non-default instances delegate missing keys to the global instance via #isDefault checks in every #defaultXxx method, so per-topic copies only override keys that are explicitly set.
- #asFullJsonDictionary collects all unary 'accessing' protocol selectors dynamically, so new settings keys are automatically included in the JSON output when a getter is added to that protocol.
"
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
	dict keysAndValuesDo: [ :k :v |
		| mutator |
		mutator := k asSymbol asMutator.
		(settings respondsTo: mutator)
			ifTrue: [ settings perform: mutator with: v ]
			ifFalse: [ Transcript crShow: ('AbSettings: skipping unknown key ''{1}''' format: { k }) ] ].
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
	aFileReference ensureDelete.
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
AbSettings >> defaultGoalSetCommand [
	self isDefault ifFalse: [ ^ self class default defaultGoalSetCommand ].
	^ '/goal'
]

{ #category : 'defaults' }
AbSettings >> defaultUseCommandOnGoalSet [
	self isDefault ifFalse: [ ^ self class default defaultUseCommandOnGoalSet ].
	^ false
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
  {"name": "codex-acp", "command": ["codex-acp"]},
  {"name": "Cursor CLI", "command": ["agent", "acp"]},
  {"name": "Kilo Code", "command": ["kilo", "acp"]},
  {"name": "Kiro CLI", "command": ["kiro-cli", "acp"]}
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
AbSettings >> defaultUseStBuddySkillOnInitialPrompt [
	self isDefault ifFalse: [ ^ self class default defaultUseStBuddySkillOnInitialPrompt ].
	^ true
]

{ #category : 'defaults' }
AbSettings >> defaultWatcherMessageThrottleSeconds [
	self isDefault ifFalse: [ ^ self class default defaultWatcherMessageThrottleSeconds ].
	^ 2
]

{ #category : 'defaults' }
AbSettings >> defaultMaxAttachmentSize [
	self isDefault ifFalse: [ ^ self class default defaultMaxAttachmentSize ].
	^ 5 * 1024 * 1024
]

{ #category : 'accessing' }
AbSettings >> goalSetCommand [

	^ self at: #goalSetCommand ifAbsent: [ self defaultGoalSetCommand ]
]

{ #category : 'accessing' }
AbSettings >> goalSetCommand: aString [

	self at: #goalSetCommand put: aString
]

{ #category : 'accessing' }
AbSettings >> useCommandOnGoalSet [

	^ self at: #useCommandOnGoalSet ifAbsent: [ self defaultUseCommandOnGoalSet ]
]

{ #category : 'accessing' }
AbSettings >> useCommandOnGoalSet: aBoolean [

	self at: #useCommandOnGoalSet put: aBoolean
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
AbSettings >> useStBuddySkillOnInitialPrompt [

	^ self
		  at: #useStBuddySkillOnInitialPrompt
		  ifAbsent: [ self defaultUseStBuddySkillOnInitialPrompt ]
]

{ #category : 'accessing' }
AbSettings >> useStBuddySkillOnInitialPrompt: aBoolean [

	self at: #useStBuddySkillOnInitialPrompt put: aBoolean
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

{ #category : 'accessing' }
AbSettings >> maxAttachmentSize [

	^ self at: #maxAttachmentSize ifAbsent: [ self defaultMaxAttachmentSize ]
]

{ #category : 'accessing' }
AbSettings >> maxAttachmentSize: anInteger [

	self at: #maxAttachmentSize put: anInteger
]

{ #category : 'accessing-convenient' }
AbSettings >> agentArgumentsPresets [
	| dict |
	dict := Dictionary new.
	self codingAgents do: [ :each |
		dict at: (each at: 'name') put: (each at: 'command') asArray ].
	^ dict
]
