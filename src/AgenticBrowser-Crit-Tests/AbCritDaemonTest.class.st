Class {
	#name : 'AbCritDaemonTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'root'
	],
	#category : 'AgenticBrowser-Crit-Tests',
	#package : 'AgenticBrowser-Crit-Tests'
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
	AbCritDaemon resetLaunchMutex.
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
AbCritDaemonTest >> readyTopicWithoutConfigNamed: aString [

	| dir topic |
	dir := self directoryNamed: aString.
	(dir / '.git') ensureCreateDirectory.
	topic := self topicAt: dir.
	AbSettings default useCrit: true.
	topic stateMachine
		handleEvent: #promptSent;
		handleEvent: #turnEnded.
	^ topic
]

{ #category : 'private' }
AbCritDaemonTest >> readyTopicNamed: aString [

	| topic |
	topic := self readyTopicWithoutConfigNamed: aString.
	(AbCritConfigFile in: topic workingDirectory path) writePort: 9080.
	^ topic
]

{ #category : 'private' }
AbCritDaemonTest >> registerRunningTopicHoldingPort: anInteger named: aString [

	| topic stub |
	topic := self topicAt: (self directoryNamed: aString).
	(AbCritConfigFile in: topic workingDirectory path) writePort: anInteger.
	stub := self daemonFor: topic.
	stub commandBlock: [ :command | '{"daemon":{"running":true}}' ].
	topic session critDaemon: stub.
	AbTopicManager forTest addTopic: topic.
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

{ #category : 'private' }
AbCritDaemonTest >> assertSpawnCommandForTopic: topicName expectedHostAndFlags: hostAndFlags [

	| daemon log |
	daemon := self daemonFor: (self readyTopicNamed: topicName).
	daemon spawn.
	log := AbSettings defaultAgenticBrowserRootDirectory / '_crit-logs' / (topicName , '.log').
	self assert: (self spawnCount: daemon) equals: 1.
	self
		assert: daemon executedCommands last
		equals: ('crit --no-open {1} >> {2} 2>&1 &' format: {
				 hostAndFlags.
				 log fullName shellQuoted })
]

{ #category : 'tests' }
AbCritDaemonTest >> testTopicCachesCritDaemon [

	| topic |
	topic := self readyTopicNamed: 'cached'.
	self assert: topic critDaemon identicalTo: topic critDaemon.
	self assert: topic critDaemon topic identicalTo: topic
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
AbCritDaemonTest >> testIsAvailableWithoutConfigFile [

	| topic daemon |
	topic := self readyTopicWithoutConfigNamed: 'noconfig'.
	daemon := AbCritDaemon forTopic: topic.
	self deny: (topic workingDirectory path / '.crit.config.json') exists.
	self assert: daemon unavailableReason isNil.
	self assert: daemon isAvailable
]

{ #category : 'tests' }
AbCritDaemonTest >> testIsAvailableWhenSwitchAndGitHold [

	| topic daemon |
	topic := self readyTopicNamed: 'ready'.
	daemon := AbCritDaemon forTopic: topic.
	self assert: daemon unavailableReason isNil.
	self assert: daemon isAvailable.
	self assert: daemon refusalReasonOnStart isNil
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
	self assert: daemon refusalReasonOnStart equals: 'topic status is initial'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonWhenTopicIsWorking [

	| topic |
	topic := self readyTopicWithoutConfigNamed: 'working'.
	topic stateMachine handleEvent: #promptSent.
	self assert: (AbCritDaemon forTopic: topic) refusalReasonOnStart equals: 'topic status is working'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonWhenTopicIsWaitingForHuman [

	| topic |
	topic := self readyTopicWithoutConfigNamed: 'waiting'.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: (AbCritDaemon forTopic: topic) refusalReasonOnStart equals: 'topic status is waitingForHuman'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonWhenTopicIsGoalAchieved [

	| topic |
	topic := self readyTopicWithoutConfigNamed: 'achieved'.
	topic stateMachine
		handleEvent: #promptSent;
		handleEvent: #goalReached.
	self assert: (AbCritDaemon forTopic: topic) refusalReasonOnStart equals: 'topic status is goalAchieved'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartRefusalReasonPrefersUnavailableOverInitial [

	| topic |
	topic := self topicAt: (self directoryNamed: 'both').
	self assert: (AbCritDaemon forTopic: topic) refusalReasonOnStart equals: 'useCrit is false'
]

{ #category : 'tests' }
AbCritDaemonTest >> testPollBudgetIsTenSeconds [

	| daemon |
	daemon := AbCritDaemon forTopic: (self readyTopicNamed: 'budget').
	self assert: daemon pollAttemptsUntilRunning * daemon pollDelayUntilRunning asMilliSeconds equals: 10000
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartTimeoutReasonDerivesSecondsFromPollBudget [

	| daemon |
	daemon := AbCritDaemon forTopic: (self readyTopicNamed: 'reason').
	self
		assert: daemon startTimeoutReason
		equals: 'crit did not start within 10 seconds on port 9080 (the port may be in use by another process)'.
	daemon
		pollAttemptsUntilRunning: 4;
		pollDelayUntilRunning: 500 milliSeconds.
	self assert: (daemon startTimeoutReason beginsWith: 'crit did not start within 2 seconds on port 9080')
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
	self assert: topic messages last text equals: 'Crit review: http://localhost:9080/ (crit asks once to trust this project''s hooks when you first press Finish)'.
	self assert: (self spawnCount: daemon) equals: 0.
	self assert: topic isEndTurn
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
	log := AbSettings defaultAgenticBrowserRootDirectory / '_crit-logs' / 'spawn.log'.
	self assert: url equals: 'http://192.168.1.10:9080/'.
	self assert: topic messages last text equals: 'Crit review: http://192.168.1.10:9080/ (crit asks once to trust this project''s hooks when you first press Finish)'.
	self assert: (self spawnCount: daemon) equals: 1.
	self assert: (daemon executedCommands second includesSubstring: '--host 0.0.0.0').
	self assert: (daemon executedCommands second includesSubstring: '--allow-unauthenticated-network').
	self assert: (daemon executedCommands second includesSubstring: log fullName).
	self assert: (daemon executedCommands second includesSubstring: '2>&1 &')
]

{ #category : 'tests' }
AbCritDaemonTest >> testSpawnAllowsUnauthenticatedNetworkAccessByDefault [

	self
		assertSpawnCommandForTopic: 'network'
		expectedHostAndFlags: '--host 0.0.0.0 --allow-unauthenticated-network'
]

{ #category : 'tests' }
AbCritDaemonTest >> testSpawnBindsToLocalhostWhenUnauthenticatedNetworkAccessIsDisallowed [

	AbSettings default critAllowUnauthenticatedNetwork: false.
	self
		assertSpawnCommandForTopic: 'localhost'
		expectedHostAndFlags: '--host 127.0.0.1'
]

{ #category : 'tests' }
AbCritDaemonTest >> testReviewUrlUsesRequestedHostWhenUnauthenticatedNetworkAccessIsAllowed [

	| daemon |
	daemon := self daemonFor: (self readyTopicNamed: 'lan-url').
	self
		assert: (daemon reviewUrlForHost: '192.168.1.10')
		equals: 'http://192.168.1.10:9080/'
]

{ #category : 'tests' }
AbCritDaemonTest >> testReviewUrlUsesLocalhostWhenUnauthenticatedNetworkAccessIsDisallowed [

	| daemon |
	daemon := self daemonFor: (self readyTopicNamed: 'loopback-url').
	AbSettings default critAllowUnauthenticatedNetwork: false.
	self
		assert: (daemon reviewUrlForHost: '192.168.1.10')
		equals: 'http://localhost:9080/'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewTimesOutWhenDaemonNeverRuns [

	| topic daemon reason log |
	topic := self readyTopicNamed: 'timeout'.
	daemon := self daemonFor: topic.
	log := AbSettings defaultAgenticBrowserRootDirectory / '_crit-logs' / 'timeout.log'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: daemon startTimeoutReason.
	self assert: (reason includesSubstring: 'on port 9080 (the port may be in use by another process)').
	self assert: topic messages last text equals: 'Crit review failed: ' , reason , ' (log: ' , log fullName , ')'.
	self assert: (self spawnCount: daemon) equals: 1.
	self assert: topic isEndTurn
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewTimeoutReportsCritOutputOfThisSpawn [

	| daemon reason |
	daemon := self daemonFor: (self readyTopicNamed: 'no-changes').
	daemon logFile ensureDelete.
	self appendLog: 'Output of an earlier spawn' of: daemon.
	reason := self timeoutReasonOf: daemon onSpawn: [
		          self appendLog: 'No changed files found.\\  crit  review changed files' withCRs of: daemon ].
	self assert: reason equals: 'crit did not start within 0 seconds on port 9080: No changed files found.'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewTimeoutSuggestsPortConflictWhenLogShrankSinceSpawn [

	| daemon reason |
	daemon := self daemonFor: (self readyTopicNamed: 'shrunk-log').
	daemon logFile ensureDelete.
	self appendLog: 'Output of an earlier spawn' of: daemon.
	reason := self timeoutReasonOf: daemon onSpawn: [
		          daemon logFile ensureDelete.
		          self appendLog: 'x' of: daemon ].
	self assert: reason equals: 'crit did not start within 0 seconds on port 9080 (the port may be in use by another process)'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewTimeoutSuggestsPortConflictWhenLogIsInvalidUtf8 [

	| daemon reason |
	daemon := self daemonFor: (self readyTopicNamed: 'invalid-utf8-log').
	daemon logFile ensureDelete.
	daemon logFile parent ensureCreateDirectory.
	reason := self timeoutReasonOf: daemon onSpawn: [
		          daemon logFile binaryWriteStreamDo: [ :stream | stream nextPutAll: #[ 16rE3 16r81 ] ] ].
	self assert: reason equals: 'crit did not start within 0 seconds on port 9080 (the port may be in use by another process)'
]

{ #category : 'tests' }
AbCritDaemonTest >> testIsDaemonRunningSignalsCritErrorWhenStatusLacksRunning [

	| daemon error |
	daemon := self daemonFor: (self readyTopicNamed: 'no-running').
	daemon statusReplies add: '{"daemon":{}}'.
	error := [ daemon isDaemonRunning. nil ] on: AbCritError do: [ :ex | ex ].
	self assert: error kind equals: #statusUnavailable.
	self assert: error messageText equals: 'crit status failed (is crit on PATH?)'
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewStatusFailurePostsMessageWithoutSpawning [

	| topic daemon reason log |
	topic := self readyTopicNamed: 'path'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: 'not-json'.
	log := AbSettings defaultAgenticBrowserRootDirectory / '_crit-logs' / 'path.log'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'crit status failed (is crit on PATH?)'.
	self assert: topic messages last text equals: 'Crit review failed: crit status failed (is crit on PATH?) (log: ' , log fullName , ')'.
	self assert: (self spawnCount: daemon) equals: 0.
	self assert: topic isEndTurn
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
	self assert: reason equals: daemon startTimeoutReason.
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
	self assert: topic isEndTurn
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewWithoutConfigWritesPortThenReportsUrl [

	| topic daemon url port |
	topic := self readyTopicWithoutConfigNamed: 'no-config'.
	daemon := self daemonFor: topic.
	daemon statusReplies
		add: '{"daemon":{"running":false}}';
		add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :startedUrl :startedPort | url := startedUrl. port := startedPort ]
		ifFailed: [ :reason | self fail: reason ].
	self assert: url equals: 'http://localhost:9080/'.
	self assert: port equals: 9080.
	self assert: (AbCritConfigFile in: topic workingDirectory path) port equals: 9080.
	self assert: (self spawnCount: daemon) equals: 1
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewMovesPortHeldByAnotherRunningTopic [

	| topic daemon port |
	self registerRunningTopicHoldingPort: 9080 named: 'holder'.
	topic := self readyTopicNamed: 'mover'.
	daemon := self daemonFor: topic.
	daemon statusReplies
		add: '{"daemon":{"running":false}}';
		add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :startedUrl :startedPort | port := startedPort ]
		ifFailed: [ :reason | self fail: reason ].
	self assert: port equals: 9081.
	self assert: (AbCritConfigFile in: topic workingDirectory path) port equals: 9081
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewReusesRunningDaemonWithoutMovingItsPort [

	| topic daemon port |
	self registerRunningTopicHoldingPort: 9080 named: 'holder'.
	topic := self readyTopicNamed: 'keeper'.
	daemon := self daemonFor: topic.
	daemon statusReplies add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :startedUrl :startedPort | port := startedPort ]
		ifFailed: [ :reason | self fail: reason ].
	self assert: port equals: 9080.
	self assert: (AbCritConfigFile in: topic workingDirectory path) port equals: 9080.
	self assert: (self spawnCount: daemon) equals: 0
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewFailsWithoutSpawningWhenPortRangeIsExhausted [

	| topic daemon reason |
	AbSettings default critPortRange: '9080-9080'.
	self registerRunningTopicHoldingPort: 9080 named: 'holder'.
	topic := self readyTopicWithoutConfigNamed: 'exhausted'.
	daemon := self daemonFor: topic.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ].
	self assert: reason equals: 'crit port range exhausted: 9080-9080'.
	self assert: (topic messages last text beginsWith: 'Crit review failed: crit port range exhausted').
	self assert: (self spawnCount: daemon) equals: 0
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

{ #category : 'private' }
AbCritDaemonTest >> appendLog: aString of: aDaemon [

	aDaemon logFile parent ensureCreateDirectory.
	aDaemon logFile writeStreamDo: [ :stream |
		stream
			setToEnd;
			nextPutAll: aString;
			lf ].
	^ ''
]

{ #category : 'private' }
AbCritDaemonTest >> timeoutReasonOf: aDaemon onSpawn: aBlock [

	| reason |
	aDaemon commandBlock: [ :cmd |
		(cmd beginsWith: 'crit status')
			ifTrue: [ '{"daemon":{"running":false}}' ]
			ifFalse: [
				aBlock value.
				'' ] ].
	[ aDaemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :failed | reason := failed ] ]
		ensure: [ aDaemon logFile ensureDelete ].
	^ reason
]

{ #category : 'private' }
AbCritDaemonTest >> startSpawning: aDaemon [

	aDaemon statusReplies
		add: '{"daemon":{"running":false}}';
		add: '{"daemon":{"running":true}}'.
	aDaemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | ]
		ifFailed: [ :reason | self fail: reason ]
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewSpawnWritesFinishHooksForTopic [

	| topic hooks |
	topic := self readyTopicNamed: 'hooks'.
	self startSpawning: (self daemonFor: topic).
	hooks := (STONJSON fromString: (topic workingDirectory path / '.crit.config.json') contents) at: 'hooks'.
	AbCritReviewFinishResultsManager default finishKinds do: [ :kind |
		self
			assert: (hooks at: 'on_finish_' , kind)
			equals: 'inline:cat > ''' , (AbCritReviewFinishResultsManager default fileForTopicId: topic topicId kind: kind) fullName , '''' ].
	self assert: AbCritReviewFinishResultsManager default directory exists
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewWithUserFinishHookStartsAndSaysDeliveryIsOff [

	| topic userHooks dir |
	topic := self readyTopicNamed: 'user-hook'.
	dir := topic workingDirectory path.
	userHooks := Dictionary new at: 'on_finish_unresolved' put: 'inline:echo mine'; yourself.
	(dir / '.crit.config.json') writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: (Dictionary new at: 'port' put: 9080; at: 'hooks' put: userHooks; yourself)) ].
	self startSpawning: (self daemonFor: topic).
	self assert: ((STONJSON fromString: (dir / '.crit.config.json') contents) at: 'hooks') equals: userHooks.
	self assert: (topic messages anySatisfy: [ :each | each text includesSubstring: 'automatic delivery' ]).
	self assert: (topic messages last text beginsWith: 'Crit review: http://localhost:9080/')
]

{ #category : 'tests' }
AbCritDaemonTest >> testStartReviewAwaitsFirstFinishAndDeletesStaleResults [

	| topic daemon files |
	topic := self readyTopicNamed: 'await'.
	daemon := self daemonFor: topic.
	files := AbCritReviewFinishResultsManager default filesForTopicId: topic topicId.
	AbCritReviewFinishResultsManager default directory ensureCreateDirectory.
	[
	files do: [ :file | file ensureCreateFile ].
	daemon statusReplies add: '{"daemon":{"running":true}}'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | ]
		ifFailed: [ :reason | self fail: reason ].
	self assert: daemon isAwaitingFirstFinish.
	self assert: (files noneSatisfy: [ :file | file exists ]) ]
		ensure: [ files do: [ :file | file ensureDelete ] ]
]

{ #category : 'tests' }
AbCritDaemonTest >> testFailedStartDoesNotAwaitFirstFinish [

	| daemon |
	daemon := self daemonFor: (self readyTopicNamed: 'await-failed').
	daemon statusReplies add: 'not-json'.
	daemon
		startReviewForHost: 'localhost'
		ifStarted: [ :url :port | self fail: url ]
		ifFailed: [ :reason | ].
	self deny: daemon isAwaitingFirstFinish
]
