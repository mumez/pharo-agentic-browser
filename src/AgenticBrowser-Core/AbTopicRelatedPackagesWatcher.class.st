Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching',
		'pendingPackageApprovals',
		'lastAnnouncedAtByPackage'
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
			topic addSystemMessage:
				aPackageName , ' was modified; .st files have been updated' ]
		ifFalse: [
			Transcript crShow:
				'[AbLog] postSystemMessageAndExport: system message suppressed for '
				, aPackageName ].
	topic workingDirectory exportPackageNamed: aPackageName.
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleClassChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImportingFromSource ifTrue: [
		Transcript crShow:
			'[AbLog] handleClassChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement classAffected package name asString.
	self handlePackageChange: pkgName
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleMethodChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImportingFromSource ifTrue: [
		Transcript crShow:
			'[AbLog] handleMethodChange: suppressed during import'.
		^ self ].
	pkgName := anAnnouncement methodPackage name asString.
	self handlePackageChange: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handlePackageChange: aPackageName [

	(pendingPackageApprovals includes: aPackageName) ifTrue: [ ^ self ].
	pendingPackageApprovals add: aPackageName.
	[ self doHandlePackageChange: aPackageName ] fork
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> doHandlePackageChange: aPackageName [

	| matchesPrefix |
	matchesPrefix := topic packagePrefixes anySatisfy: [ :prefix |
						 prefix match: aPackageName ].
	matchesPrefix
		ifTrue: [ self requestApprovalToExportPackage: aPackageName ]
		ifFalse: [ self requestApprovalToTrackPackage: aPackageName ]
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	isWatching := false.
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

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> start [

	isWatching := true.
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
	Transcript crShow:'[AbLog] requestApprovalToTrackPackage: ' , aPackageName.
	[
	approvalResponse := topic requestApproval:
		                    'Package ''' , aPackageName
		                    , ''' was modified but does not match any tracked prefix.'
		                    , String cr
		                    , 'Add this package to tracked prefixes and export? (yes/no)'.
	Transcript crShow:'[AbLog] requestApprovalToTrackPackage: got response=' , approvalResponse printString.
	(self shouldProceedWithExportForApprovalResponse: approvalResponse)
		ifTrue: [
			topic addPackagePrefix: aPackageName.
			self postSystemMessageAndExport: aPackageName ]
		ifFalse: [
			topic addSystemMessage:
				'Ignored package change for ' , aPackageName
				, ' (not added to tracked prefixes).' ] ]
		ensure: [
			Transcript crShow:'[AbLog] requestApprovalToTrackPackage: ensure cleanup for ' , aPackageName.
			pendingPackageApprovals remove: aPackageName ifAbsent: [] ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> requestApprovalToExportPackage: aPackageName [

	| approvalResponse |
	Transcript crShow:'[AbLog] requestApprovalToExportPackage: ' , aPackageName.
	[
	approvalResponse := topic requestApproval:
		                    'Package ''' , aPackageName
		                    , ''' was modified.'
		                    , String cr
		                    , 'Export .st files now? (yes/no)'.
	Transcript crShow:'[AbLog] requestApprovalToExportPackage: got response=' , approvalResponse printString.
	(self shouldProceedWithExportForApprovalResponse: approvalResponse)
		ifTrue: [ self postSystemMessageAndExport: aPackageName ]
		ifFalse: [
			topic addSystemMessage:
				'Skipped export for ' , aPackageName , ' (approval denied).' ] ]
		ensure: [
			Transcript crShow:'[AbLog] requestApprovalToExportPackage: ensure cleanup for ' , aPackageName.
			pendingPackageApprovals remove: aPackageName ifAbsent: [] ]
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> shouldProceedWithExportForApprovalResponse: aResponseSymbol [

	^ aResponseSymbol = #allowAlways
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> shouldAnnouncePackageChangeFor: aPackageName at: aTimestamp [

	| lastTimestamp shouldAnnounce |
	lastTimestamp := lastAnnouncedAtByPackage
		                 at: aPackageName
		                 ifAbsent: [ nil ].
	shouldAnnounce := lastTimestamp isNil or: [
		                  aTimestamp - lastTimestamp >= self messageThrottleDuration ].
	shouldAnnounce ifTrue: [
		lastAnnouncedAtByPackage at: aPackageName put: aTimestamp ].
	^ shouldAnnounce
]

{ #category : 'operations' }
AbTopicRelatedPackagesWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	isWatching := false
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic [
	^ topic
]

{ #category : 'accessing' }
AbTopicRelatedPackagesWatcher >> topic: anAbTopic [

	topic := anAbTopic.
	isWatching := false
]
