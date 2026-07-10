Class {
	#name : 'AbTopicListPresenterTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'presenter',
		'topic'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'accessing' }
AbTopicListPresenterTest >> presenter: aPresenter [

	presenter := aPresenter
]

{ #category : 'running' }
AbTopicListPresenterTest >> setUp [

	super setUp.
	self presenter: AbTopicListPresenter new.
	self topic: (self newTopic: 'TestTopic').
]

{ #category : 'running' }
AbTopicListPresenterTest >> tearDown [

	presenter release.
	super tearDown
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testApplyUpdatedExternalPackagesForAddsPrefixesAndClearsPendingList [

	topic addUpdatedExternalPackageName: 'AgenticBrowser-Core'.
	presenter applyUpdatedExternalPackagesFor: topic.
	self assert: (topic hasPackagePrefix: 'AgenticBrowser-Core').
	self assert: topic updatedExternalPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testApplyUpdatedExternalPackagesForWithNoPendingPackagesAddsMessage [

	presenter applyUpdatedExternalPackagesFor: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [
			m text includesSubstring: 'No externally updated packages' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testAutoExportPreconditionsForNewTopic [

	"Verifies the preconditions for the auto-export path in onPackagePrefixSet:.
	 A freshly-created topic with a matching prefix has:
	   - at least one matching package
	   - no existing working directory on disk
	 The actual export (SisServer call) is verified in the integration smoke test."

	topic addPackagePrefix: 'AgenticBrowser-*'.
	self assert: topic matchingPackageNames notEmpty.
	self deny: topic workingDirectory path exists
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testIconForEndTurnTopic [

	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: (presenter iconNameFor: topic) equals: #greenCircle
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testIconForInitialTopic [

	self assert: (presenter iconNameFor: topic) equals: #blueCircle
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testIconForWaitingForHumanTopic [

	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: (presenter iconNameFor: topic) equals: #question
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testIconForWorkingTopic [

	topic stateMachine handleEvent: #promptSent.
	self assert: (presenter iconNameFor: topic) equals: #sparkle
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnClearSessionIdRequestClearsSelectedTopicSession [

	| topicListMock mockClient |
	topic session sessionId: 'session-1'.
	mockClient := MockObject new.
	mockClient on: #disconnect verify: [ ].
	topic session client: mockClient.
	topicListMock := MockObject new.
	topicListMock on: #selectedItem verify: [ topic ].
	presenter instVarNamed: 'topicList' put: topicListMock.

	presenter onClearSessionIdRequest.

	self verify: topicListMock.
	self verify: mockClient.
	self assert: topic sessionId isNil
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetEmptyPrefixAddsNewProjectMessage [

	topic packagePrefixes: Set new.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'new project' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetNoMatchAddsSystemMessage [

	topic addPackagePrefix: 'NonExistentXYZ99-*'.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'No packages match' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnSetWorkingDirectorySetsWorkingDirectoryPath [

	| testPath |
	testPath := '/tmp/test-working-dir'.
	topic workingDirectoryPath: testPath.
	self assert: topic workingDirectoryPath equals: testPath
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testSortedTopicsByLastUpdatedNewestFirst [

	| older newer sorted |
	older := self newTopic: 'Older'.
	older addSystemMessage: 'first'.
	(Delay forMilliseconds: 1) wait.
	newer := self newTopic: 'Newer'.
	newer addSystemMessage: 'second'.
	presenter sortMode: #lastUpdated.
	sorted := presenter sortedTopics: {
			          older.
			          newer }.
	self assert: sorted first equals: newer.
	self assert: sorted second equals: older
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testSortedTopicsByTitle [

	| alpha beta sorted |
	alpha := self newTopic: 'Alpha'.
	beta := self newTopic: 'Beta'.
	presenter sortMode: #title.
	sorted := presenter sortedTopics: {
			          beta.
			          alpha }.
	self assert: sorted first equals: alpha.
	self assert: sorted second equals: beta
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForIncludesAgentName [

	topic agentArguments: #( 'opencode' ).
	self assert: (presenter topicListLabelFor: topic) equals: 'ab-test-TestTopic (opencode)'.

	topic agentArguments: #( 'claude-agent-acp' ).
	self assert: (presenter topicListLabelFor: topic) equals: 'ab-test-TestTopic (claude-agent-acp)'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForReturnsIconAndTitle [

	topic agentArguments: #(  ).
	self assert: (presenter topicListLabelFor: topic) equals: 'ab-test-TestTopic'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testRefreshAfterTopicAddedShowsNewTopic [

	| manager newTopic |
	manager := AbTopicManager forTest.
	presenter topicManager: manager.
	presenter subscribeToTopicManager.

	newTopic := self newTopic: 'SyncedTopic'.
	manager addTopic: newTopic.
	presenter refresh.

	self assert: (presenter topicList items includes: newTopic)
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicAddedAnnouncerSubscriptionIsRegistered [
	"Verify that AbTopicAdded subscription is wired on the manager announcer"

	| manager |
	manager := AbTopicManager forTest.
	presenter topicManager: manager.
	presenter subscribeToTopicManager.

	self assert: (manager announcer subscriptions subscriptions
		anySatisfy: [ :s | s announcementClass = AbTopicAdded ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testPresenterUpdatesTopicManagerOnAbTopicManagerLoaded [

	| newManager |
	presenter topicManager: AbTopicManager forTest.
	presenter subscribeToTopicManager.
	newManager := AbTopicManager new.
	AbTopicManager announcer announce: (AbTopicManagerLoaded topicManager: newManager).
	self assert: presenter topicManager == newManager
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testPresenterUnsubscribesFromOldTopicManagerAfterLoad [

	| oldManager newManager newTopic received |
	oldManager := AbTopicManager forTest.
	presenter topicManager: oldManager.
	presenter subscribeToTopicManager.
	newManager := AbTopicManager new.
	received := false.
	AbTopicManager announcer announce: (AbTopicManagerLoaded topicManager: newManager).
	newTopic := self newTopic: 'OldManagerTopic'.
	oldManager addTopic: newTopic.
	"If still subscribed to oldManager, topicList items would change"
	self deny: (presenter topicList items includes: newTopic)
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testUnsubscribeFromTopicManagerAlsoUnsubscribesFromClassAnnouncer [

	| newManager |
	presenter topicManager: AbTopicManager forTest.
	presenter subscribeToTopicManager.
	presenter unsubscribeFromTopicManager.
	newManager := AbTopicManager new.
	AbTopicManager announcer announce: (AbTopicManagerLoaded topicManager: newManager).
	self deny: presenter topicManager == newManager
]

{ #category : 'accessing' }
AbTopicListPresenterTest >> topic: anAbTopic [

	topic := anAbTopic
]
