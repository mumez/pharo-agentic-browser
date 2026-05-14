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

{ #category : 'instance creation' }
AbSettings class >> defaultCopied [

	^ self new initFrom: self default
]

{ #category : 'class initialization' }
AbSettings class >> initialize [

	default := nil
]

{ #category : 'persistence' }
AbSettings class >> defaultAgenticBrowserRootDirectory [

	^ Smalltalk imageDirectory / 'agentic-browser'
]

{ #category : 'persistence' }
AbSettings class >> fileName [

	^ 'ab-settings.ston'
]

{ #category : 'persistence' }
AbSettings class >> defaultFileReference [

	^ self defaultAgenticBrowserRootDirectory / self fileName
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

	self saveTo: aFileReference settings: self default
]

{ #category : 'persistence' }
AbSettings class >> saveTo: aFileReference settings: anAbSettings [

	aFileReference parent ensureCreateDirectory.
	aFileReference writeStreamDo: [ :stream |
		(STONWriter on: stream)
			prettyPrint: true;
			nextPut: anAbSettings settingsDict ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds [

	^ self
		  at: #aiPermissionWaitTimeoutSeconds
		  ifAbsentPut: [ self defaultAiPermissionWaitTimeoutSeconds ]
]

{ #category : 'accessing' }
AbSettings >> aiPermissionWaitTimeoutSeconds: anInteger [

	self at: #aiPermissionWaitTimeoutSeconds put: anInteger
]

{ #category : 'converting' }
AbSettings >> asDictionary [

	^ self keys inject: Dictionary new into: [ :dict :key |
		  dict
			  at: key put: (self perform: key);
			  yourself ]
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

	^ 1800
]

{ #category : 'defaults' }
AbSettings >> defaultExportApprovalWaitTimeoutSeconds [

	^ 30
]

{ #category : 'defaults' }
AbSettings >> defaultWatcherMessageThrottleDuration [

	^ 2 seconds
]

{ #category : 'accessing' }
AbSettings >> exportApprovalWaitTimeoutSeconds [

	^ self
		  at: #exportApprovalWaitTimeoutSeconds
		  ifAbsentPut: [ self defaultExportApprovalWaitTimeoutSeconds ]
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

	| current |
	current := self instVarNamed: #settingsDict.
	current ifNil: [
		current := Dictionary new.
		self instVarNamed: #settingsDict put: current ].
	^ current
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration [

	^ self
		  at: #watcherMessageThrottleDuration
		  ifAbsentPut: [ self defaultWatcherMessageThrottleDuration ]
]

{ #category : 'accessing' }
AbSettings >> watcherMessageThrottleDuration: aDuration [

	self at: #watcherMessageThrottleDuration put: aDuration
]
