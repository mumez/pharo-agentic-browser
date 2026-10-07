Class {
	#name : 'AbCritDaemonTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'root'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbCritDaemonTest >> setUp [

	super setUp.
	AbSettings initialize.
	self root: (FileLocator temp / ('ab-crit-daemon-' , UUID new asString36)).
	self root ensureCreateDirectory
]

{ #category : 'running' }
AbCritDaemonTest >> tearDown [

	self root exists ifTrue: [ self root deleteAll ].
	AbSettings initialize.
	AbCritDaemon resetLaunchMutexes.
	super tearDown
]

{ #category : 'accessing' }
AbCritDaemonTest >> root [

	^ root
]

{ #category : 'accessing' }
AbCritDaemonTest >> root: aFileReference [

	root := aFileReference
]

{ #category : 'private' }
AbCritDaemonTest >> directoryNamed: aString [

	| dir |
	dir := self root / aString.
	dir ensureCreateDirectory.
	^ dir
]

{ #category : 'private' }
AbCritDaemonTest >> topicAt: aDirectory [

	| topic |
	topic := self newTopic: aDirectory basename.
	topic workingDirectoryPath: aDirectory fullName.
	^ topic
]

{ #category : 'private' }
AbCritDaemonTest >> readyTopicNamed: aString [

	| dir topic |
	dir := self directoryNamed: aString.
	(dir / '.git') ensureCreateDirectory.
	topic := self topicAt: dir.
	AbSettings default useCrit: true.
	(AbCritConfigFile in: dir) writePort: 9080.
	topic stateMachine handleEvent: #promptSent.
	^ topic
]

{ #category : 'private' }
AbCritDaemonTest >> daemonFor: aTopic [

	^ AbStubCritDaemon forTopic: aTopic
]

{ #category : 'private' }
AbCritDaemonTest >> spawnCount: aDaemon [

	^ aDaemon executedCommands count: [ :each | each beginsWith: 'crit --no-open' ]
]

{ #category : 'tests' }
AbCritDaemonTest >> testUnavailableReasonWhenUseCritIsFalse [

	| topic |
	topic := self readyTopicNamed: 'off'.
	AbSettings default useCrit: false.
	self assert: (AbCritDaemon forTopic: topic) unavailableReason equals: 'useCrit is false'.
	self deny: (AbCritDaemon forTopic: topic) isAvailable
]

{ #category : 'tests' }
AbCritDaemonTest >> testIsValidReviewHostAcceptsHostnamesAndRejectsInjection [

	self assert: (AbCritDaemon isValidReviewHost: 'localhost').
	self assert: (AbCritDaemon isValidReviewHost: '192.168.1.10').
	self assert: (AbCritDaemon isValidReviewHost: 'host.example.com').
	self deny: (AbCritDaemon isValidReviewHost: '').
	self deny: (AbCritDaemon isValidReviewHost: 'evil' , String lf , 'x').
	self deny: (AbCritDaemon isValidReviewHost: 'a/b').
	self deny: (AbCritDaemon isValidReviewHost: 'a b')
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewRejectsInvalidHostWithoutACommand [

	| topic daemon reason |
	topic := self readyTopicNamed: 'bad-host'.
	daemon := self daemonFor: topic.
	daemon
		startReviewForHost: 'evil http://x'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'invalid host'.
	self assert: daemon executedCommands isEmpty
]

{ #category : 'tests' }
AbCritDaemonTest >> testUnavailableReasonWhenGitIsMissing [

	| topic |
	topic := self topicAt: (self directoryNamed: 'nogit').
	AbSettings default useCrit: true.
	(AbCritConfigFile in: topic workingDirectory path) writePort: 9080.
	self assert: (AbCritDaemon forTopic: topic) unavailableReason equals: 'working directory has no .git'
]

{ #category : 'tests' }
AbCritDaemonTest >> testUnavailableReasonWhenPortIsMissing [

	| dir topic |
	dir := self directoryNamed: 'noport'.
	(dir / '.git') ensureCreateDirectory.
	topic := self topicAt: dir.
	AbSettings default useCrit: true.
	self assert: (AbCritDaemon forTopic: topic) unavailableReason equals: 'no crit port assigned'
]

{ #category : 'tests' }
AbCritDaemonTest >> testIsAvailableWhenSwitchGitAndPortHold [

	| topic daemon |
	topic := self readyTopicNamed: 'ready'.
	daemon := AbCritDaemon forTopic: topic.
	self assert: daemon unavailableReason isNil.
	self assert: daemon isAvailable.
	self assert: daemon startRefusalReason isNil
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonWhenTopicIsInitial [

	| dir topic daemon |
	dir := self directoryNamed: 'initial'.
	(dir / '.git') ensureCreateDirectory.
	topic := self topicAt: dir.
	AbSettings default useCrit: true.
	(AbCritConfigFile in: dir) writePort: 9080.
	daemon := AbCritDaemon forTopic: topic.
	self assert: daemon isAvailable.
	self assert: daemon startRefusalReason equals: 'topic status is initial'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonPrefersUnavailableOverInitial [

	| topic |
	topic := self topicAt: (self directoryNamed: 'both').
	self assert: (AbCritDaemon forTopic: topic) startRefusalReason equals: 'useCrit is false'
]

{ #category : 'tests' }
AbCritDaemonTest >> testPollBudgetIsTenSeconds [

	| daemon |
	daemon := AbCritDaemon forTopic: (self readyTopicNamed: 'budget').
	self assert: daemon readyPollAttempts * daemon readyPollDelay asMilliSeconds equals: 10000
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewReusesRunningDaemon [

	| topic daemon url port |
	topic := self readyTopicNamed: 'running'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :startedUrl :startedPort | url := startedUrl. port := startedPort ]
		ifFailed: [ :reason | self fail: reason ].
	self assert: url equals: 'http://localhost:9080/'.
	self assert: port equals: 9080.
	self assert: topic messages last text equals: 'Crit review: http://localhost:9080/'.
	self assert: (self spawnCount: daemon) equals: 0.
	self assert: topic isWorking
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewSpawnsThenReportsUrl [

	| topic daemon url log |
	topic := self readyTopicNamed: 'spawn'.
	daemon := self daemonFor: topic.
	daemon statusReplies
		add: '{"daemon":{"running":false}}';
		add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: '192.168.1.10'
		ifStarted: [ :startedUrl :startedPort | url := startedUrl ]
		ifFailed: [ :reason | self fail: reason ].
	log := AbSettings defaultAgenticBrowserRootDirectory / 'crit-logs' / 'spawn.log'.
	self assert: url equals: 'http://192.168.1.10:9080/'.
	self assert: topic messages last text equals: 'Crit review: http://192.168.1.10:9080/'.
	self assert: (self spawnCount: daemon) equals: 1.
	self assert: (daemon executedCommands second includesSubstring: '--host 0.0.0.0').
	self assert: (daemon executedCommands second includesSubstring: '--allow-unauthenticated-network').
	self assert: (daemon executedCommands second includesSubstring: log fullName).
	self assert: (daemon executedCommands second includesSubstring: '2>&1 &')
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewTimesOutWhenDaemonNeverRuns [

	| topic daemon reason log |
	topic := self readyTopicNamed: 'timeout'.
	daemon := self daemonFor: topic.
	log := AbSettings defaultAgenticBrowserRootDirectory / 'crit-logs' / 'timeout.log'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'crit did not start within 10 seconds'.
	self assert: topic messages last text equals: 'Crit review failed: crit did not start within 10 seconds (log: ' , log fullName , ')'.
	self assert: (self spawnCount: daemon) equals: 1.
	self assert: topic isWorking
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewStatusFailurePostsMessageWithoutSpawning [

	| topic daemon reason log |
	topic := self readyTopicNamed: 'path'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: 'not-json'.
	log := AbSettings defaultAgenticBrowserRootDirectory / 'crit-logs' / 'path.log'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'crit status failed (is crit on PATH?)'.
	self assert: topic messages last text equals: 'Crit review failed: crit status failed (is crit on PATH?) (log: ' , log fullName , ')'.
	self assert: (self spawnCount: daemon) equals: 0.
	self assert: topic isWorking
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewPollStatusErrorsCountAsNotRunning [

	| topic daemon reason |
	topic := self readyTopicNamed: 'poll'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: '{"daemon":{"running":false}}'.
	3 timesRepeat: [ daemon statusReplies add: 'not-json' ].
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'crit did not start within 10 seconds'.
	self assert: (self spawnCount: daemon) equals: 1
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewSpawnErrorPostsMessageAndLeavesStatus [

	| topic daemon reason |
	topic := self readyTopicNamed: 'spawn-error'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: '{"daemon":{"running":false}}'.
	daemon commandBlock: [ :cmd |
		(cmd beginsWith: 'crit status')
			ifTrue: [ '{"daemon":{"running":false}}' ]
			ifFalse: [ Error signal: 'spawn failed' ] ].
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'spawn failed'.
	self assert: (topic messages last text includesSubstring: 'Crit review failed: spawn failed (log: ').
	self assert: topic isWorking
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewRefusesInitialWithoutACommand [

	| dir topic daemon reason |
	dir := self directoryNamed: 'refuse'.
	(dir / '.git') ensureCreateDirectory.
	topic := self topicAt: dir.
	AbSettings default useCrit: true.
	(AbCritConfigFile in: dir) writePort: 9080.
	daemon := self daemonFor: topic.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'topic status is initial'.
	self assert: daemon executedCommands isEmpty.
	self assert: topic isInitial
]

{ #category : 'private' }
AbCritDaemonTest >> gateBlockEntered: entered release: release state: state [

	^ [ :cmd |
	  (cmd beginsWith: 'crit status')
		  ifTrue: [
			  (state at: #spawned)
				  ifTrue: [ '{"daemon":{"running":true}}' ]
				  ifFalse: [
					  state at: #statusCount put: (state at: #statusCount) + 1.
					  (state at: #statusCount) = 1 ifTrue: [
						  entered signal.
						  release wait ].
					  '{"daemon":{"running":false}}' ] ]
		  ifFalse: [
			  state at: #spawned put: true.
			  '' ] ]
]

{ #category : 'private' }
AbCritDaemonTest >> start: aDaemon thenSignal: done [

	aDaemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | ]
		ifFailed: [ :reason | ].
	done signal
]

{ #category : 'tests' }
AbCritDaemonTest >> testOverlappingStartsSpawnOnce [

	| topic first second entered release done state |
	topic := self readyTopicNamed: 'mutex'.
	first := self daemonFor: topic.
	second := self daemonFor: topic.
	entered := Semaphore new.
	release := Semaphore new.
	done := Semaphore new.
	state := Dictionary new
		         at: #spawned put: false;
		         at: #statusCount put: 0;
		         yourself.
	first commandBlock: (self gateBlockEntered: entered release: release state: state).
	second commandBlock: first commandBlock.
	[ [ self start: first thenSignal: done ] fork.
	self assert: (entered waitTimeoutSeconds: 2) equals: false.
	[ self start: second thenSignal: done ] fork.
	(Delay forMilliseconds: 50) wait.
	release signal.
	self assert: (done waitTimeoutSeconds: 2) equals: false.
	self assert: (done waitTimeoutSeconds: 2) equals: false.
	self assert: (self spawnCount: first) + (self spawnCount: second) equals: 1 ]
		ensure: [ release signal ]
]
