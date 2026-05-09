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
AbTopicRelatedPackagesWatcher >> postSystemMessageAndExport: aPackageName [

	| shouldAnnounce |
	shouldAnnounce := self
		                  shouldAnnouncePackageChangeFor: aPackageName
		                  at: DateAndTime now.
	shouldAnnounce
		ifTrue: [
			self topic addSystemMessage:
				aPackageName , ' was modified; .st files have been updated' ]
		ifFalse: [
			self logger debug: 'postSystemMessageAndExport: system message suppressed for '
				, aPackageName ].
	self topic workingDirectory exportPackageNamed: aPackageName.
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
AbTopicRelatedPackagesWatcher >> trackExternalPackageChange: aPackageName [

	[
	self topic addUpdatedExternalPackageName: aPackageName ]
		ensure: [ self pendingPackageApprovals remove: aPackageName ifAbsent: [] ]
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	self isWatching: false.
	pendingPackageApprovals := Set new.
	lastAnnouncedAtByPackage := Dictionary new
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> messageThrottleDuration [

	^ AbSettings default watcherMessageThrottleDuration
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> isWatching [
	^ isWatching
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> isWatching: aBoolean [

	isWatching := aBoolean
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

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToTrackPackage: aPackageName [

	| approvalResponse |
	self logger debug: 'requestApprovalToTrackPackage: ' , aPackageName.
	[
	approvalResponse := self topic requestApproval:
		                    (self trackPackageApprovalPromptFor: aPackageName).
	self handleTrackPackageApprovalResponse: approvalResponse packageName: aPackageName ]
		ensure: [ self cleanupPendingApprovalFor: aPackageName in: 'requestApprovalToTrackPackage:' ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToExportPackage: aPackageName [

	| approvalResponse |
	self logger debug: 'requestApprovalToExportPackage: ' , aPackageName.
	[
	approvalResponse := self topic requestApproval:
		                    (self exportPackageApprovalPromptFor: aPackageName).
	self handleExportPackageApprovalResponse: approvalResponse packageName: aPackageName ]
		ensure: [ self cleanupPendingApprovalFor: aPackageName in: 'requestApprovalToExportPackage:' ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> shouldProceedWithExportForApprovalResponse: aResponseSymbol [

	^ aResponseSymbol = #allowOnce
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
AbTopicRelatedPackagesWatcher >> cleanupPendingApprovalFor: aPackageName in: aSelectorName [

	self logger debug: aSelectorName , ' ensure cleanup for ' , aPackageName.
	self pendingPackageApprovals remove: aPackageName ifAbsent: []
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> exportPackageApprovalPromptFor: aPackageName [

	^ 'Package ''' , aPackageName
	  , ''' was modified.'
	  , String cr
	  , 'Export .st files now? (yes/no)'
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleExportPackageApprovalResponse: approvalResponse packageName: aPackageName [

	self logger debug: 'requestApprovalToExportPackage: got response=' , approvalResponse printString.
	(self shouldProceedWithExportForApprovalResponse: approvalResponse)
		ifTrue: [ self postSystemMessageAndExport: aPackageName ]
		ifFalse: [
			self topic addSystemMessage:
				'Skipped export for ' , aPackageName , ' (approval denied).' ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handleTrackPackageApprovalResponse: approvalResponse packageName: aPackageName [

	self logger debug: 'requestApprovalToTrackPackage: got response=' , approvalResponse printString.
	(self shouldProceedWithExportForApprovalResponse: approvalResponse)
		ifTrue: [
			self topic addPackagePrefix: aPackageName.
			self postSystemMessageAndExport: aPackageName ]
		ifFalse: [
			self topic addSystemMessage:
				'Ignored package change for ' , aPackageName
				, ' (not added to tracked prefixes).' ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> trackPackageApprovalPromptFor: aPackageName [

	^ 'Package ''' , aPackageName
	  , ''' was modified but does not match any tracked prefix.'
	  , String cr
	  , 'Add this package to tracked prefixes and export? (yes/no)'
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> pendingPackageApprovals [

	^ pendingPackageApprovals
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> lastAnnouncedAtByPackage [

	^ lastAnnouncedAtByPackage
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	self isWatching: false
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> logger [
	^ logger ifNil: [ logger := AbLocalLogger new ]
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
