Class {
	#name : 'AbCritReviewFinishResultsManagerDeliveryTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'topicManager',
		'sentPrompts',
		'resultTopicIds',
		'finishAnnouncements'
	],
	#category : 'AgenticBrowser-Crit-Tests',
	#package : 'AgenticBrowser-Crit-Tests'
}

{ #category : 'running' }
AbCritReviewFinishResultsManagerDeliveryTest >> setUp [

	super setUp.
	AbSettings initialize.
	AbSettings default useCrit: true.
	topicManager := AbTopicManager forTest.
	sentPrompts := OrderedCollection new.
	resultTopicIds := OrderedCollection new.
	finishAnnouncements := OrderedCollection new
]

{ #category : 'running' }
AbCritReviewFinishResultsManagerDeliveryTest >> tearDown [

	resultTopicIds do: [ :topicId |
		(AbCritReviewFinishResultsManager default filesForTopicId: topicId) do: [ :file | file ensureDelete ] ].
	AbSettings initialize.
	super tearDown
]

{ #category : 'private' }
AbCritReviewFinishResultsManagerDeliveryTest >> deliverResults [

	AbCritReviewFinishResultsManager default deliverResultsToTopicsIn: topicManager
]

{ #category : 'private' }
AbCritReviewFinishResultsManagerDeliveryTest >> unresolvedPayload [

	^ '{"unresolved_count":1,"comments_unresolved_json":[{"id":"c_1","body":"please fix"}],"next_round_cmd":"crit --session s1"}'
]

{ #category : 'private' }
AbCritReviewFinishResultsManagerDeliveryTest >> writeResult: aKindSymbol containing: aString forTopicId: aTopicId [

	| file |
	resultTopicIds add: aTopicId.
	file := AbCritReviewFinishResultsManager default fileForTopicId: aTopicId kind: aKindSymbol.
	file parent ensureCreateDirectory.
	file writeStreamDo: [ :stream | stream nextPutAll: aString ].
	^ file
]

{ #category : 'private' }
AbCritReviewFinishResultsManagerDeliveryTest >> writeUnresolvedFor: aTopic [

	^ self writeResult: #unresolved containing: self unresolvedPayload forTopicId: aTopic topicId
]

{ #category : 'private' }
AbCritReviewFinishResultsManagerDeliveryTest >> topicAwaitingFirstFinish: aBoolean events: anEventCollection [

	| topic |
	topic := AbMockTopicNoPromptSend new.
	topic onSendBlock: [ :text :resources | sentPrompts add: text ].
	anEventCollection do: [ :event | topic stateMachine handleEvent: event ].
	topic critDaemon awaitingFirstFinish: aBoolean.
	topic announcer when: AbCritReviewFinished do: [ :ann | finishAnnouncements add: ann ] for: self.
	topicManager addTopic: topic.
	^ topic
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testDoesNothingWhenUseCritIsFalse [

	| topic file |
	topic := self topicAwaitingFirstFinish: true events: #( #promptSent #turnEnded ).
	file := self writeUnresolvedFor: topic.
	AbSettings default useCrit: false.
	self deliverResults.
	self assert: sentPrompts isEmpty.
	self assert: file exists.
	self assert: topic critDaemon isAwaitingFirstFinish
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testSendsPromptToIdleAwaitingTopics [

	| endTurnTopic initialTopic files |
	endTurnTopic := self topicAwaitingFirstFinish: true events: #( #promptSent #turnEnded ).
	initialTopic := self topicAwaitingFirstFinish: true events: #(  ).
	files := { endTurnTopic. initialTopic } collect: [ :each | self writeUnresolvedFor: each ].
	self deliverResults.
	self assert: sentPrompts size equals: 2.
	self assert: (sentPrompts allSatisfy: [ :each | each beginsWith: 'The review finished with 1 unresolved comment.' ]).
	self assert: (files noneSatisfy: [ :each | each exists ]).
	self deny: endTurnTopic critDaemon isAwaitingFirstFinish.
	self deny: initialTopic critDaemon isAwaitingFirstFinish
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testKeepsResultWhileTopicIsBusy [

	| workingTopic waitingTopic files |
	workingTopic := self topicAwaitingFirstFinish: true events: #( #promptSent ).
	waitingTopic := self topicAwaitingFirstFinish: true events: #( #permissionRequested ).
	files := { workingTopic. waitingTopic } collect: [ :each | self writeUnresolvedFor: each ].
	self deliverResults.
	self assert: sentPrompts isEmpty.
	self assert: (files allSatisfy: [ :each | each exists ]).
	self assert: workingTopic critDaemon isAwaitingFirstFinish.
	self assert: waitingTopic critDaemon isAwaitingFirstFinish
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testReportsFirstApprovalInAnyStatusWithoutPrompt [

	| topic file |
	topic := self topicAwaitingFirstFinish: true events: #( #promptSent ).
	file := self writeResult: #approved containing: '{"approved":true}' forTopicId: topic topicId.
	self deliverResults.
	self assert: sentPrompts isEmpty.
	self assert: topic messages last text equals: 'Crit review approved.'.
	self deny: file exists.
	self deny: topic critDaemon isAwaitingFirstFinish
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testDiscardsResultOfTopicNotAwaitingFirstFinish [

	| topic file |
	topic := self topicAwaitingFirstFinish: false events: #( #promptSent #turnEnded ).
	file := self writeUnresolvedFor: topic.
	self deliverResults.
	self assert: sentPrompts isEmpty.
	self deny: file exists
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testDiscardsResultOfUnknownTopic [

	| file |
	file := self
		        writeResult: #unresolved
		        containing: self unresolvedPayload
		        forTopicId: 'ab-test-unknown-' , UUID new asString36.
	self deliverResults.
	self deny: file exists
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testKeepsUnreadableResultForRetryWithoutStoppingOthers [

	| brokenTopic goodTopic brokenFile |
	brokenTopic := self topicAwaitingFirstFinish: true events: #( #promptSent #turnEnded ).
	goodTopic := self topicAwaitingFirstFinish: true events: #( #promptSent #turnEnded ).
	brokenFile := self writeResult: #unresolved containing: '{"unresolved_count":' forTopicId: brokenTopic topicId.
	self writeUnresolvedFor: goodTopic.
	self deliverResults.
	self assert: brokenFile exists.
	self assert: brokenTopic critDaemon isAwaitingFirstFinish.
	self assert: sentPrompts size equals: 1.
	self deny: goodTopic critDaemon isAwaitingFirstFinish
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testAnnouncesUnresolvedFinishWhenPromptIsSent [

	| topic |
	topic := self topicAwaitingFirstFinish: true events: #( #promptSent #turnEnded ).
	self writeUnresolvedFor: topic.
	self deliverResults.
	self assert: finishAnnouncements size equals: 1.
	self assert: finishAnnouncements first topic identicalTo: topic.
	self assert: finishAnnouncements first kind equals: #unresolved.
	self assert: finishAnnouncements first unresolvedCount equals: 1
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testAnnouncesApprovedFinish [

	| topic |
	topic := self topicAwaitingFirstFinish: true events: #( #promptSent ).
	self writeResult: #approved containing: '{"approved":true}' forTopicId: topic topicId.
	self deliverResults.
	self assert: finishAnnouncements size equals: 1.
	self assert: finishAnnouncements first topic identicalTo: topic.
	self assert: finishAnnouncements first kind equals: #approved.
	self assert: finishAnnouncements first unresolvedCount equals: 0
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testDoesNotAnnounceFinishWhilePromptIsHeldBack [

	| topic |
	topic := self topicAwaitingFirstFinish: true events: #( #promptSent ).
	self writeUnresolvedFor: topic.
	self deliverResults.
	self assert: finishAnnouncements isEmpty
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerDeliveryTest >> testDoesNotAnnounceDiscardedFinish [

	| topic |
	topic := self topicAwaitingFirstFinish: false events: #( #promptSent #turnEnded ).
	self writeUnresolvedFor: topic.
	self deliverResults.
	self assert: finishAnnouncements isEmpty
]
