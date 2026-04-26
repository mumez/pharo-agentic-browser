Class {
	#name : 'AbTopicRelatedPackagesWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching'
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

	topic addSystemMessage:
		aPackageName , ' が変更されたので .st ファイルを更新しました'.
	[ topic workingDirectory exportPackage: aPackageName ] fork
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
		ifFalse: [
			(UIManager default confirm:
				 'Package ''' , aPackageName
				 , ''' was modified but does not match any tracked prefix.' , String cr
				 , 'Add this package to tracked prefixes and export?')
				ifTrue: [
					topic addPackagePrefix: aPackageName.
					self announceChangeAndExport: aPackageName ] ]
]

{ #category : 'initialization' }
AbTopicRelatedPackagesWatcher >> initialize [

	isWatching := false
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
