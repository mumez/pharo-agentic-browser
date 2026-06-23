Class {
	#name : 'AbTopicManagerTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicManagerTest >> testAddTopic [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Test topic'.
	manager addTopic: topic.
	self assert: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testAddTopicAnnouncesAbTopicAdded [

	| manager topic received |
	manager := AbTopicManager forTest.
	received := nil.
	manager announcer
		when: AbTopicAdded
		do: [ :ann | received := ann topic ]
		for: self.
	[ topic := self newTopic: 'Test'.
	manager addTopic: topic.
	self assert: received == topic ]
		ensure: [ manager announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testAbTopicAddedClassTopicConstructor [

	| topic announcement |
	topic := self newTopic: 'Test topic'.
	announcement := AbTopicAdded topic: topic.
	self assert: announcement class equals: AbTopicAdded.
	self assert: announcement topic == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testAbTopicRemovedClassTopicConstructor [

	| topic announcement |
	topic := self newTopic: 'Test topic'.
	announcement := AbTopicRemoved topic: topic.
	self assert: announcement class equals: AbTopicRemoved.
	self assert: announcement topic == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testAtReturnsTopicByTopicId [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Lookup topic by at:'.
	manager addTopic: topic.
	self assert: (manager at: topic topicId) == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testCleanupAllTopicsStopsWatchersAndUnsubscribesWorkingDirectories [

	| manager topic hasSubscription |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Cleanup topic'.
	manager addTopic: topic.
	topic startWatching.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self assert: topic relatedPackagesWatcher isWatching.
	self assert: hasSubscription.
	[
	manager cleanupAllTopics.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self deny: topic relatedPackagesWatcher isWatching.
	self deny: hasSubscription ]
		ensure: [ topic stopWatching ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testDefaultFileReferenceIsInAgenticBrowserDirectory [

	| file |
	file := AbTopicManager defaultFileReference.
	self assert: (file fullName includesSubstring: 'agentic-browser').
	self assert: (file fullName endsWith: 'ab-topics.fuel')
]

{ #category : 'tests' }
AbTopicManagerTest >> testDefaultReturnsSameInstance [

	self assert: AbTopicManager default == AbTopicManager default
]

{ #category : 'tests' }
AbTopicManagerTest >> testInitializeStopsActiveWatchersBeforeReset [

	| topic watcher originalDefault |
	originalDefault := AbTopicManager default.
	AbTopicManager default: AbTopicManager new.
	topic := self newTopic: 'Orphan during init'.
	AbTopicManager default addTopic: topic.
	topic startWatching.
	watcher := topic relatedPackagesWatcher.
	self assert: watcher isWatching.
	[ AbTopicManager initialize.
	  self deny: watcher isWatching ]
		ensure: [
			AbTopicManager default: originalDefault.
			AbTopicManager forTest: nil ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testForTestReturnsSameInstance [

	self assert: AbTopicManager forTest == AbTopicManager forTest
]

{ #category : 'tests' }
AbTopicManagerTest >> testLoadDoesNothingWhenPersistenceFileDoesNotExist [

	| previousTopicsCount |
	"This test works because AbTopicManager forTest != AbTopicManager default.
	 We only need to confirm load doesn't raise when the file is absent."
	AbTopicManager defaultFileReference exists ifTrue: [ ^ self skip ].
	previousTopicsCount := AbTopicManager default topics size.
	"Should silently do nothing when file does not exist"
	[ AbTopicManager load ]
		on: Error
		do: [ :e | self fail: 'load raised error when file absent: ' , e messageText ].
	self assert: AbTopicManager default topics size equals: previousTopicsCount
]

{ #category : 'tests' }
AbTopicManagerTest >> testLoadFromRestoresTopicStatus [

	| manager topic file loaded |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'End turn topic'.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	manager addTopic: topic.
	file := FileReference newTempFilePrefix: 'ab-topics-status-' suffix: '.fuel'.
	[
	manager saveTo: file.
	loaded := AbTopicManager loadFrom: file.
	self assert: loaded topics first status equals: #endTurn ]
		ensure: [ file ensureDelete ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testLoadFromRestoresWorkingDirectoryPath [

	| manager topic path file loaded |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Path topic'.
	path := (FileLocator temp / ('ab-path-test-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	manager addTopic: topic.
	file := FileReference newTempFilePrefix: 'ab-topics-path-' suffix: '.fuel'.
	[
	manager saveTo: file.
	loaded := AbTopicManager loadFrom: file.
	self assert: loaded topics first workingDirectoryPath equals: path ]
		ensure: [ file ensureDelete ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopic [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Test topic'.
	manager addTopic: topic.
	manager removeTopic: topic.
	self deny: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopicAnnouncesAbTopicRemoved [

	| manager topic removedAnnouncementClass received |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Test topic'.
	manager addTopic: topic.
	removedAnnouncementClass := Smalltalk at: #AbTopicRemoved ifAbsent: [ nil ].
	self assert: removedAnnouncementClass notNil.
	received := nil.
	manager announcer
		when: removedAnnouncementClass
		do: [ :ann | received := ann topic ]
		for: self.
	[
	manager removeTopic: topic.
	self assert: received == topic ]
		ensure: [ manager announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopicStopsrelatedPackagesWatcher [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Test topic'.
	manager addTopic: topic.
	topic startWatching.
	self assert: topic relatedPackagesWatcher isWatching.
	[
	manager removeTopic: topic.
	self deny: topic relatedPackagesWatcher isWatching ]
		ensure: [ topic stopWatching ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopicUnsubscribesWorkingDirectoryFromSisServer [

	| manager topic hasSubscription |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Test topic'.
	manager addTopic: topic.
	topic startWatching.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self assert: hasSubscription.
	[
	manager removeTopic: topic.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self deny: hasSubscription ]
		ensure: [ topic stopWatching ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testSaveToAndLoadFromRoundTrip [

	| manager topic file loaded |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Persisted topic'.
	manager addTopic: topic.
	file := FileReference newTempFilePrefix: 'ab-topics-test-' suffix: '.fuel'.
	[
	manager saveTo: file.
	loaded := AbTopicManager loadFrom: file.
	self assert: loaded topics size equals: 1.
	self assert: loaded topics first title equals: 'ab-test-Persisted topic'.
	self assert: loaded topics first topicId equals: topic topicId.
	self assert: (loaded instVarNamed: 'announcer') isNil ]
		ensure: [ file ensureDelete ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testSessionClientIsNilAndSessionIdIsPreservedAfterFuelRoundTrip [

	| topic session bytes materialized |
	topic := self newTopic: 'Session round-trip'.
	session := topic session.
	"Simulate a connected state by manually setting non-nil stand-ins"
	session client: 'fake-client'.
	session sessionId: 'fake-session-id'.
	bytes := FLSerializer serializeToByteArray: topic.
	materialized := FLMaterializer materializeFromByteArray: bytes.
	self assert: materialized session client isNil.
	self assert: materialized session sessionId equals: 'fake-session-id'
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicForWorkingDirectoryPath [

	| manager topic path |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Path Lookup'.
	path := (FileLocator temp / ('ab-topic-path-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	manager addTopic: topic.
	self assert: (manager topicForWorkingDirectoryPath: path) == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicLazyInstVarsAreNilAfterFuelRoundTrip [

	| topic bytes materialized |
	topic := self newTopic: 'Lazy instVars'.
	"Force-create the lazy instVars so they are non-nil before serialization"
	topic announcer.
	topic workingDirectory.
	topic relatedPackagesWatcher.
	topic logger.
	bytes := FLSerializer serializeToByteArray: topic.
	materialized := FLMaterializer materializeFromByteArray: bytes.
	self assert: (materialized instVarNamed: 'announcer') isNil.
	self assert: (materialized instVarNamed: 'workingDirectory') isNil.
	self assert: (materialized instVarNamed: 'relatedPackagesWatcher') isNil.
	self assert: (materialized instVarNamed: 'logger') isNil
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicStatusIsPreservedAfterFuelRoundTrip [

	| topic bytes materialized |
	topic := self newTopic: 'Status round-trip'.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic status equals: #endTurn.
	bytes := FLSerializer serializeToByteArray: topic.
	materialized := FLMaterializer materializeFromByteArray: bytes.
	self assert: materialized status equals: #endTurn
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicNamedReturnsNilWhenNoMatch [

	| manager |
	manager := AbTopicManager forTest.
	self assert: (manager topicNamed: 'nonexistent') isNil
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicNamedReturnsTopic [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := self newTopic: 'Named topic'.
	topic name: 'my-topic'.
	manager addTopic: topic.
	self assert: (manager topicNamed: 'my-topic') == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicNamedWithDuplicatesReturnsByTopicIdOrder [

	| manager topic1 topic2 result |
	manager := AbTopicManager forTest.
	topic1 := self newTopic: 'First'.
	topic2 := self newTopic: 'Second'.
	topic1 name: 'shared-name'.
	topic2 name: 'shared-name'.
	manager addTopic: topic1.
	manager addTopic: topic2.
	result := manager topicNamed: 'shared-name'.
	self assert: result name equals: 'shared-name'.
	self assert: result topicId equals: ({ topic1. topic2 } asSortedCollection: [ :a :b | a topicId < b topicId ]) first topicId
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsInitiallyEmpty [

	self assert: AbTopicManager forTest topics isEmpty
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsNamedReturnsAllMatchingTopics [

	| manager topic1 topic2 topic3 result |
	manager := AbTopicManager forTest.
	topic1 := self newTopic: 'First'.
	topic2 := self newTopic: 'Second'.
	topic3 := self newTopic: 'Third'.
	topic1 name: 'shared-name'.
	topic2 name: 'shared-name'.
	topic3 name: 'other-name'.
	manager addTopic: topic1.
	manager addTopic: topic2.
	manager addTopic: topic3.
	result := manager topicsNamed: 'shared-name'.
	self assert: result size equals: 2.
	self assert: (result includes: topic1).
	self assert: (result includes: topic2).
	self deny: (result includes: topic3)
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsNamedReturnsEmptyWhenNoMatch [

	| manager |
	manager := AbTopicManager forTest.
	self assert: (manager topicsNamed: 'nonexistent') isEmpty
]
