Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching',
		'pendingPackageApprovals',
		'lastAnnouncedAtByPackage',
		'logger'
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
AbTopicRelatedPackagesWatcher >> cleanupPendingApprovalFor: aPackageName in: aSelectorName [

	self logger debug: aSelectorName , ' ensure cleanup for ' , aPackageName.
	self pendingPackageApprovals remove: aPackageName ifAbsent: []
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> doHandlePackageChange: aPackageName [

	| matchesPrefix |
	matchesPrefix := self topic packagePrefixes anySatisfy: [ :prefix |
						 prefix match: aPackageName ].
	matchesPrefix
		ifTrue: [ self requestApprovalToExportPackage: aPackageName ]
		ifFalse: [ self trackExternalPackageChange: aPackageName ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> exportPackageApprovalPromptFor: aPackageName [

	^ 'Package ''' , aPackageName
	  , ''' was modified.'
	  , String cr
	  , 'Export .st files now? (yes/no)'
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleClassChange: anAnnouncement [

	| pkgName |
	self topic workingDirectory isImportingFromSource ifTrue: [
		self logger debug: 'handleClassChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement classAffected package name asString.
	self handlePackageChange: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleExportPackageApprovalResponse: approvalOption packageName: aPackageName [

	self logger debug: 'requestApprovalToExportPackage: got response=' , approvalOption printString.
	(self shouldProceedWithExportForApprovalResponse: approvalOption)
		ifTrue: [ self postSystemMessageAndExport: aPackageName ]
		ifFalse: [
			self topic addSystemMessage:
				'Skipped export for ' , aPackageName , ' (approval denied).' ]
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleMethodChange: anAnnouncement [

	| pkgName |
	self topic workingDirectory isImportingFromSource ifTrue: [
		self logger debug: 'handleMethodChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement methodPackage name asString.
	self handlePackageChange: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handlePackageChange: aPackageName [

	(self pendingPackageApprovals includes: aPackageName) ifTrue: [ ^ self ].
	self pendingPackageApprovals add: aPackageName.
	[ self doHandlePackageChange: aPackageName ] fork
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	self isWatching: false.
	pendingPackageApprovals := Set new.
	lastAnnouncedAtByPackage := Dictionary new
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

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> messageThrottleDuration [

	^ AbSettings default watcherMessageThrottleDuration
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> pendingPackageApprovals [

	^ pendingPackageApprovals
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> postSystemMessageAndExport: aPackageName [

	| shouldAnnounce |
	shouldAnnounce := self
		                  shouldAnnouncePackageChangeFor: aPackageName
		                  at: DateAndTime now.
	shouldAnnounce
		ifTrue: [
			self topic sendPrompt:
				'{1} was modified; {1}/*.st files have been updated!' format: {aPackageName} ].
	self topic workingDirectory exportPackageNamed: aPackageName.
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToExportPackage: aPackageName [

	| approvalOption |
	self logger debug: 'requestApprovalToExportPackage: ' , aPackageName.
	[
	approvalOption := self topic requestPackageExport:
		                    (self exportPackageApprovalPromptFor: aPackageName).
	self handleExportPackageApprovalResponse: approvalOption packageName: aPackageName ]
		ensure: [ self cleanupPendingApprovalFor: aPackageName in: 'requestApprovalToExportPackage:' ]
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

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

	self isWatching: true.
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

	[
	self topic addUpdatedExternalPackageName: aPackageName ]
		ensure: [ self pendingPackageApprovals remove: aPackageName ifAbsent: [] ]
]
