"
I monitor Pharo image changes for packages related to a topic and coordinate export approval with the agent.

Responsibility:
- I subscribe to SystemAnnouncer for MethodAnnouncement and ClassAnnouncement events.
- When a changed package matches the topic's packagePrefixes, I ask the topic for export approval before writing .st files.
- When a changed package does not match, I record it in the topic's updatedExternalPackageNames for later manual action.
- I suppress all change handling while a package import from source is in progress, preventing re-export loops.
- I throttle approval requests per package: if approval was granted recently, subsequent changes are exported without prompting again.
- I throttle chat notifications per package using a configurable minimum interval.

Collaborators:
- AbTopic: I am owned by a topic and delegate approval requests, logging, and system messages back to it.
- AbWorkingDirectory: I call it to export classes when approval is granted.
- SystemAnnouncer: I subscribe to image change events while watching.

Public API and Key Messages:
- #start - Begin watching; subscribes to SystemAnnouncer and starts the worker process.
- #stop - Cease watching; unsubscribes and terminates the worker process.
- #isWatching - Returns whether watching is currently active.

Internal Representation:
- changeQueue - SharedQueue of (className -> packageName) pairs consumed by the worker process.
- workerProcess - Background Smalltalk process that drains changeQueue and handles each change.
- lastAnnouncedAtByPackage - Dictionary tracking last notification timestamp per package for chat throttling.
- lastApprovalGrantedAtByPackage - Dictionary tracking last approval-granted timestamp per package for approval throttling.
- isWatching - Guard flag; prevents double-start and ensures clean shutdown.

Implementation Points:
- Change events arrive on the SystemAnnouncer thread and are put on changeQueue immediately; a dedicated background process handles them to avoid blocking the announcer.
- Import suppression uses AbWorkingDirectory>>importNestingCount (a nesting counter) rather than a simple boolean to handle nested imports correctly.
- Class-side method changes produce a 'ClassName class' key; normalizedClassNameFrom: strips the ' class' suffix before processing.
"
Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching',
		'lastAnnouncedAtByPackage',
		'lastApprovalGrantedAtByPackage',
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
AbTopicRelatedPackagesWatcher >> exportApprovalPromptFor: aPackageName [

	^ ('Package "{1}" was modified.' format: {aPackageName})
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

	self changeQueue nextPut: aClassName -> aPackageName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleExportClassApprovalResponse: approvalOption className: aClassName in: aPackageName [

	self logger debug: 'handleExportClassApprovalResponse:className: got approvalOption=' , approvalOption printString.
	(self shouldProceedWithExportForApprovalResponse: approvalOption)
		ifTrue: [
			lastApprovalGrantedAtByPackage at: aPackageName put: DateAndTime now.
			self exportClassWithPostIfNeeded: aClassName in: aPackageName ]
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
	lastApprovalGrantedAtByPackage := Dictionary new.
	changeQueue := nil.
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
AbTopicRelatedPackagesWatcher >> lastApprovalGrantedAtByPackage [

	^ lastApprovalGrantedAtByPackage
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> logger [
	^ self topic logger
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> changeQueue [
	^ changeQueue ifNil: [ changeQueue := SharedQueue new ]
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> workerProcess [
	^ workerProcess
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> messageThrottleDuration [

	^ self topic settings watcherMessageThrottleDuration
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
AbTopicRelatedPackagesWatcher >> isApprovalThrottledFor: aPackageName [

	| lastGranted |
	lastGranted := lastApprovalGrantedAtByPackage at: aPackageName ifAbsent: [ nil ].
	^ lastGranted notNil and: [ DateAndTime now - lastGranted < self messageThrottleDuration ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToExportClass: aClassName in: aPackageName [

	| approvalOption |
	self logger debug: 'requestApprovalToExportClass:in: ' , aClassName , ' in ' , aPackageName.
	(self isApprovalThrottledFor: aPackageName)
		ifTrue: [
			self logger debug: 'requestApprovalToExportClass:in: throttled, exporting without approval'.
			self exportClassWithPostIfNeeded: aClassName in: aPackageName.
			^ self ].
	approvalOption := self topic requestPackageExport:
		                    (self exportApprovalPromptFor: aPackageName).
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
AbTopicRelatedPackagesWatcher >> normalizedClassNameFrom: aClassName [

	^ aClassName copyReplaceAll: ' class' with: ''
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> runWorkerLoop [

	[ isWatching ] whileTrue: [
		| item |
		item := self changeQueue next.
		item ifNotNil: [
			self doHandleClassChange: (self normalizedClassNameFrom: item key) in: item value ] ]
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

	self isWatching ifTrue: [ ^ self ].
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

	self isWatching ifFalse: [ ^ self ].
	SystemAnnouncer uniqueInstance unsubscribe: self.
	changeQueue nextPut: nil.
	workerProcess ifNotNil: [ :p | p terminate ].
	workerProcess := nil.
	self isWatching: false
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
