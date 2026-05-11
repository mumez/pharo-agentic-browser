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
	topic := AbTopic new title: 'Test topic'.
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
	[ topic := AbTopic new title: 'Test'.
	manager addTopic: topic.
	self assert: received == topic ]
		ensure: [ manager announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testAtReturnsTopicByTopicId [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Lookup topic by at:'.
	manager addTopic: topic.
	self assert: (manager at: topic topicId) == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testCleanupAllTopicsStopsWatchersAndUnsubscribesWorkingDirectories [

	| manager topic hasSubscription |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Cleanup topic'.
	manager addTopic: topic.
	topic startWatching.
	topic workingDirectory subscribeToSisServerImportEvents.
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
		ensure: [
		topic stopWatching.
		topic workingDirectory unsubscribeFromSisServerImportEvents ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testDefaultReturnsSameInstance [

	self assert: AbTopicManager default == AbTopicManager default
]

{ #category : 'tests' }
AbTopicManagerTest >> testForTestReturnsSameInstance [

	self assert: AbTopicManager forTest == AbTopicManager forTest
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopic [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	manager removeTopic: topic.
	self deny: (manager topics includes: topic)
]

{ #category : 'tests' }
AbTopicManagerTest >> testRemoveTopicStopsrelatedPackagesWatcher [

	| manager topic |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Test topic'.
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
	topic := AbTopic new title: 'Test topic'.
	manager addTopic: topic.
	topic workingDirectory subscribeToSisServerImportEvents.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self assert: hasSubscription.
	[
	manager removeTopic: topic.
	hasSubscription := SisServer current announcer subscriptions subscriptions
		anySatisfy: [ :each | each subscriber == topic workingDirectory ].
	self deny: hasSubscription ]
		ensure: [ topic workingDirectory unsubscribeFromSisServerImportEvents ]
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicForWorkingDirectoryPath [

	| manager topic path |
	manager := AbTopicManager forTest.
	topic := AbTopic new title: 'Path Lookup'.
	path := (FileLocator temp / ('ab-topic-path-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	manager addTopic: topic.
	self assert: (manager topicForWorkingDirectoryPath: path) == topic
]

{ #category : 'tests' }
AbTopicManagerTest >> testSessionClientAndSessionIdAreNilAfterFuelRoundTrip [

	| topic session bytes materialized |
	topic := AbTopic new title: 'Session round-trip'.
	session := topic session.
	"Simulate a connected state by manually setting non-nil stand-ins"
	session client: 'fake-client'.
	session sessionId: 'fake-session-id'.
	bytes := FLSerializer serializeToByteArray: topic.
	materialized := FLMaterializer materializeFromByteArray: bytes.
	self assert: materialized session client isNil.
	self assert: materialized session sessionId isNil
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicLazyInstVarsAreNilAfterFuelRoundTrip [

	| topic bytes materialized |
	topic := AbTopic new title: 'Lazy instVars'.
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
	topic := AbTopic new title: 'Status round-trip'.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic status equals: #endTurn.
	bytes := FLSerializer serializeToByteArray: topic.
	materialized := FLMaterializer materializeFromByteArray: bytes.
	self assert: materialized status equals: #endTurn
]

{ #category : 'tests' }
AbTopicManagerTest >> testTopicsInitiallyEmpty [

	self assert: AbTopicManager forTest topics isEmpty
]
