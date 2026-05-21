Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching',
		'lastAnnouncedAtByPackage',
		'logger',
		'changeQueue',
		'workerProcess'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicRelatedPackagesWatcher class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> doHandleClassChange: aClassName in: aPackageName [

	| matchesPrefix |
	matchesPrefix := self topic packagePrefixes anySatisfy: [ :prefix |
		                 prefix match: aPackageName ].
	matchesPrefix
		ifTrue: [ self requestApprovalToExportClass: aClassName in: aPackageName ]
		ifFalse: [ self trackExternalPackageChange: aPackageName ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> exportPackageApprovalPromptFor: aPackageName [

	^ ('Package "{1}" was modified.') format: {aPackageName})
	  , String cr
	  , 'Export .st files now? (yes/no)'
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleClassChange: anAnnouncement [

	| pkgName className |
	self topic workingDirectory isImportingFromSource ifTrue: [
		self logger debug: 'handleClassChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement classAffected package name asString.
	className := anAnnouncement classAffected name asString.
	self handleClassChangeNamed: className in: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleClassChangeNamed: aClassName in: aPackageName [

	changeQueue nextPut: aClassName -> aPackageName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleExportClassApprovalResponse: approvalOption className: aClassName in: aPackageName [

	self logger debug: 'handleExportClassApprovalResponse:className: got approvalOption=' , approvalOption printString.
	(self shouldProceedWithExportForApprovalResponse: approvalOption)
		ifTrue: [ self exportClassWithPostIfNeeded: aClassName in: aPackageName ]
		ifFalse: [
			self topic addSystemMessage:
				'Skipped export for ' , aPackageName , ' (approval denied).' ]
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleMethodChange: anAnnouncement [

	| pkgName className |
	self topic workingDirectory isImportingFromSource ifTrue: [
		self logger debug: 'handleMethodChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement methodPackage name asString.
	className := anAnnouncement method methodClass instanceSide name asString.
	self handleClassChangeNamed: className in: pkgName
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	self isWatching: false.
	lastAnnouncedAtByPackage := Dictionary new.
	changeQueue := SharedQueue new.
	workerProcess := nil
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> isWatching [
	^ isWatching
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> isWatching: aBoolean [

	isWatching := aBoolean
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> lastAnnouncedAtByPackage [

	^ lastAnnouncedAtByPackage
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> changeQueue [
	^ changeQueue
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> workerProcess [
	^ workerProcess
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> messageThrottleDuration [

	^ selt topic watcherMessageThrottleDuration
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> exportClassWithPostIfNeeded: aClassName in: aPackageName [

	| shouldAnnounce |
	shouldAnnounce := self
		                  shouldAnnouncePackageChangeFor: aPackageName
		                  at: DateAndTime now.
	self topic workingDirectory exportClassNamed: aClassName in: aPackageName.
	shouldAnnounce ifTrue: [
		self topic sendPrompt:
			('{1} was modified; {1}/*.st files have been updated!' format: { aPackageName }) ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToExportClass: aClassName in: aPackageName [

	| approvalOption |
	self logger debug: 'requestApprovalToExportClass:in: ' , aClassName , ' in ' , aPackageName.
	approvalOption := self topic requestPackageExport:
		                    (self exportPackageApprovalPromptFor: aPackageName).
	self handleExportClassApprovalResponse: approvalOption className: aClassName in: aPackageName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> shouldAnnouncePackageChangeFor: aPackageName at: aTimestamp [

	| lastTimestamp shouldAnnounce |
	lastTimestamp := self lastAnnouncedAtByPackage
		                 at: aPackageName
		                 ifAbsent: [ nil ].
	shouldAnnounce := lastTimestamp isNil or: [
		                  aTimestamp - lastTimestamp >= self messageThrottleDuration ].
	shouldAnnounce ifTrue: [
		self lastAnnouncedAtByPackage at: aPackageName put: aTimestamp ].
	^ shouldAnnounce
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> shouldProceedWithExportForApprovalResponse: aResponseSymbol [

	^ aResponseSymbol = AbConstants allowOnce
	  or: [ aResponseSymbol = AbConstants allowAlways ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> runWorkerLoop [

	[ isWatching ] whileTrue: [
		| item |
		item := changeQueue next.
		item ifNotNil: [
			self doHandleClassChange: item key in: item value ] ]
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

	changeQueue := SharedQueue new.
	self isWatching: true.
	workerProcess := [ self runWorkerLoop ] newProcess
		name: 'AgenticBrowser package watcher';
		priority: Processor userBackgroundPriority;
		yourself.
	workerProcess resume.
	SystemAnnouncer uniqueInstance
		when: MethodAnnouncement
		do: [ :ann | self handleMethodChange: ann ]
		for: self.
	SystemAnnouncer uniqueInstance
		when: ClassAnnouncement
		do: [ :ann | self handleClassChange: ann ]
		for: self
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	self isWatching: false.
	changeQueue nextPut: nil.
	workerProcess ifNotNil: [ :p | p terminate ]
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic: anAbTopic [

	topic := anAbTopic.
	self isWatching: false
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> trackExternalPackageChange: aPackageName [

	self topic addUpdatedExternalPackageName: aPackageName
]
