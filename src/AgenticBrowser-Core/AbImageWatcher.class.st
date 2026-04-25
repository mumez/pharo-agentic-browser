Class {
	#name : 'AbImageWatcher',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'isWatching'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbImageWatcher class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'event handling' }
AbImageWatcher >> handleClassChange: anAnnouncement [

	topic workingDirectory isImporting ifTrue: [ ^ self ].
	[ topic workingDirectory exportPackage: anAnnouncement classAffected package name ] fork
]

{ #category : 'event handling' }
AbImageWatcher >> handleMethodChange: anAnnouncement [

	topic workingDirectory isImporting ifTrue: [ ^ self ].
	[ topic workingDirectory exportPackage: anAnnouncement methodPackage name ] fork
]

{ #category : 'initialization' }
AbImageWatcher >> initialize [

	isWatching := false
]

{ #category : 'accessing' }
AbImageWatcher >> isWatching [
	^ isWatching
]

{ #category : 'operations' }
AbImageWatcher >> start [

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
AbImageWatcher >> stop [

	SystemAnnouncer uniqueInstance unsubscribe: self.
	isWatching := false
]

{ #category : 'accessing' }
AbImageWatcher >> topic [
	^ topic
]

{ #category : 'accessing' }
AbImageWatcher >> topic: anAbTopic [

	topic := anAbTopic.
	isWatching := false
]
