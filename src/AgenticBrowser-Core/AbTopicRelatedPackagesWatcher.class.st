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
AbTopicRelatedPackagesWatcher >> announceChangeAndExport: aPackageName [

	(self shouldAnnouncePackageChangeFor: aPackageName at: DateAndTime now)
		ifTrue: [
			topic addSystemMessage:
				aPackageName , ' was modified; .st files have been updated' ].
	topic workingDirectory exportPackage: aPackageName
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleClassChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImporting ifTrue: [ ^ self ].
	pkgName := anAnnouncement classAffected package name asString.
	self handlePackageChange: pkgName
]

{ #category : 'event handling' }
AbTopicRelatedPackagesWatcher >> handleMethodChange: anAnnouncement [

	| pkgName |
	topic workingDirectory isImporting ifTrue: [ ^ self ].
	pkgName := anAnnouncement methodPackage name asString.
	self handlePackageChange: pkgName
]

{ #category : 'private' }
AbTopicRelatedPackagesWatcher >> handlePackageChange: aPackageName [

	| matchesPrefix |
	matchesPrefix := topic packagePrefixes anySatisfy: [ :prefix |
						 prefix match: aPackageName ].
	matchesPrefix
		ifTrue: [ self announceChangeAndExport: aPackageName ]
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
	(pendingPackageApprovals includes: aPackageName) ifTrue: [ ^ self ].
	pendingPackageApprovals add: aPackageName.
	[
	approvalResponse := topic requestApproval:
		                    'Package ''' , aPackageName
		                    , ''' was modified but does not match any tracked prefix.'
		                    , String cr
		                    , 'Add this package to tracked prefixes and export? (yes/no)'.
	approvalResponse = #allowAlways
		ifTrue: [
			topic addPackagePrefix: aPackageName.
			self announceChangeAndExport: aPackageName ]
		ifFalse: [
			topic addSystemMessage:
				'Ignored package change for ' , aPackageName
				, ' (not added to tracked prefixes).' ] ]
		ensure: [ pendingPackageApprovals remove: aPackageName ifAbsent: [] ]
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
