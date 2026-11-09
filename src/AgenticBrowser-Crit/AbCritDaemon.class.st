"
I am the crit review daemon for one topic's working directory.

Responsibility:
- I decide whether crit review is available, and why a start must be refused.
- I start or reuse the detached crit daemon and report one system message plus one callback.
- Before spawning, I ensure the working directory has a crit port no other running crit holds, creating .crit.config.json when it is missing, and that it has AgenticBrowser's finish hooks, which write each Finish result to a file of AbCritReviewFinishResultsManager.
- After every successful start I await the first finish: I delete the topic's stale result files and remember that the first result is still to be delivered. Later results reach the agent through crit itself.
- I serialize all starts, across directories, so overlapping starts spawn once and never pick the same port.
- I never stop crit, and I never signal to my caller.
- When crit does not start in time, I report the first line crit wrote to the log since the spawn, or a possible port conflict when it wrote nothing.

Collaborators:
- AbTopic: I read its working directory, status, and logger, and I post the review message on it.
- AbCritConfigFile: I ask it to ensure the port and the finish hooks before spawning, and read the port through one cached instance.
- AbCritReviewFinishResultsManager: I ask it to delete my topic's result files when a start succeeds.
- AbTopicSession: It caches me, one per topic.
- AbSettings: I read #useCrit, #critAllowUnauthenticatedNetwork (bind to all interfaces with unauthenticated access, or to localhost only; the review URL host is always localhost when bind is loopback), and the crit log directory.
- AbStubCritDaemon: Tests override #runShellCommand: so no process is spawned.

Public API and Key Messages:
- AbCritDaemon class>>forTopic: - Daemon for one topic.
- #isAvailable / #unavailableReason / #refusalReasonOnStart - Whether the control is shown (useCrit and .git) and whether a start may proceed (only while the topic is #endTurn).
- #isDaemonRunning - Whether crit status reports a running daemon; signals an AbCritError when the status does not report it, and lets a JSON parse Error through.
- #startReviewForHost:ifStarted:ifFailed: - Synchronous start. ifStarted: receives the url and port. ifFailed: receives the reason.
- #isAwaitingFirstFinish - Whether the first Finish result since the last successful start is still to be delivered.

Internal Representation:
- topic - The AbTopic whose working directory crit serves.
- configFile - Lazily created AbCritConfigFile for the working directory; reset before ensuring the port so the file is read again.
- pollAttemptsUntilRunning / pollDelayUntilRunning - How many status checks to make, and the pause between them. Defaults are 20 and 500 ms.
- awaitingFirstFinish - True from a successful start until the first result is delivered. Not persisted (AbTopicSession excludes me from Fuel), so after an image restart the user starts the review again.
- logSizeBeforeSpawn - Byte size of the log file just before the last spawn, so a start timeout reports only what that spawn wrote (e.g. crit's 'No changed files found.').
- launchMutex (class) - One Mutex for all directories, covering status, port selection, spawn, and poll.
"
Class {
	#name : 'AbCritDaemon',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'configFile',
		'pollAttemptsUntilRunning',
		'pollDelayUntilRunning',
		'awaitingFirstFinish',
		'logSizeBeforeSpawn'
	],
	#classInstVars : [
		'launchMutex'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'instance creation' }
AbCritDaemon class >> forTopic: anAbTopic [

	^ self new
		  topic: anAbTopic;
		  yourself
]

{ #category : 'testing' }
AbCritDaemon class >> isValidReviewHost: aString [

	^ aString isString and: [
		  aString notEmpty and: [
			  aString allSatisfy: [ :char |
				  char isAlphaNumeric or: [ #($. $- $:) includes: char ] ] ] ]
]

{ #category : 'class initialization' }
AbCritDaemon class >> initialize [

	self resetLaunchMutex
]

{ #category : 'private' }
AbCritDaemon class >> launchMutex [

	^ launchMutex ifNil: [ launchMutex := Mutex new ]
]

{ #category : 'private' }
AbCritDaemon class >> resetLaunchMutex [

	launchMutex := nil
]

{ #category : 'accessing' }
AbCritDaemon >> topic [

	^ topic
]

{ #category : 'accessing' }
AbCritDaemon >> topic: anAbTopic [

	topic := anAbTopic
]

{ #category : 'accessing' }
AbCritDaemon >> pollAttemptsUntilRunning [

	^ pollAttemptsUntilRunning ifNil: [ 20 ]
]

{ #category : 'accessing' }
AbCritDaemon >> pollAttemptsUntilRunning: anInteger [

	pollAttemptsUntilRunning := anInteger
]

{ #category : 'accessing' }
AbCritDaemon >> pollDelayUntilRunning [

	^ pollDelayUntilRunning ifNil: [ 500 milliSeconds ]
]

{ #category : 'accessing' }
AbCritDaemon >> pollDelayUntilRunning: aDuration [

	pollDelayUntilRunning := aDuration
]

{ #category : 'accessing' }
AbCritDaemon >> awaitingFirstFinish [

	^ awaitingFirstFinish ifNil: [ false ]
]

{ #category : 'accessing' }
AbCritDaemon >> awaitingFirstFinish: aBoolean [

	awaitingFirstFinish := aBoolean
]

{ #category : 'accessing' }
AbCritDaemon >> logSizeBeforeSpawn [

	^ logSizeBeforeSpawn
]

{ #category : 'accessing' }
AbCritDaemon >> logSizeBeforeSpawn: anInteger [

	logSizeBeforeSpawn := anInteger
]

{ #category : 'testing' }
AbCritDaemon >> isAwaitingFirstFinish [

	^ self awaitingFirstFinish
]

{ #category : 'testing' }
AbCritDaemon >> isAvailable [

	^ self unavailableReason isNil
]

{ #category : 'accessing' }
AbCritDaemon >> unavailableReason [

	AbSettings default useCrit ifFalse: [ ^ 'useCrit is false' ].
	(self directory / '.git') exists ifFalse: [ ^ 'working directory has no .git' ].
	^ nil
]

{ #category : 'accessing' }
AbCritDaemon >> refusalReasonOnStart [

	^ self unavailableReason ifNil: [
		  self topic isEndTurn ifFalse: [ 'topic status is ' , self topic status ] ]
]

{ #category : 'operations' }
AbCritDaemon >> startReviewForHost: aHostString ifStarted: started ifFailed: failed [

	[ (self class isValidReviewHost: aHostString) ifFalse: [
		  ^ self onFailDo: failed reason: 'invalid host' ].
	self refusalReasonOnStart ifNotNil: [ :reason | ^ self onFailDo: failed reason: reason ].
	self withLaunchMutexDo: [
		self launchForHost: aHostString ifStarted: started ifFailed: failed ] ]
		on: Error
		do: [ :ex | self onFailDo: failed reason: ex messageText ]
]

{ #category : 'private' }
AbCritDaemon >> launchForHost: aHostString ifStarted: started ifFailed: failed [

	| running url |
	running := [ self isDaemonRunning ] on: Error do: [ nil ].
	running ifNil: [ ^ self onFailDo: failed reason: 'crit status failed (is crit on PATH?)' ].
	running ifFalse: [
		self ensurePort.
		self ensureFinishHooks.
		[ self spawn ] on: Error do: [ :ex | ^ self onFailDo: failed reason: ex messageText ].
		self waitUntilRunning ifFalse: [
			^ self onFailDo: failed reason: self startTimeoutReason ] ].
	self awaitFirstFinish.
	url := self reviewUrlForHost: aHostString.
	self topic addSystemMessage: 'Crit review: ' , url
		, ' (crit asks once to trust this project''s hooks when you first press Finish)'.
	started value: url value: self configFile port
]

{ #category : 'private' }
AbCritDaemon >> ensurePort [

	self configFile: nil.
	AbCritConfigFile ensurePortIn: self topic workingDirectory
]

{ #category : 'private' }
AbCritDaemon >> ensureFinishHooks [

	^ (self configFile ensureFinishHooksFor: self topic) ifFalse: [
		self topic addSystemMessage:
			'Crit review: automatic delivery of the first review result is off, because .crit.config.json already defines its own on_finish hook' ]
]

{ #category : 'private' }
AbCritDaemon >> awaitFirstFinish [

	self reviewFinishResultsManager deleteFilesFor: self topic.
	self awaitingFirstFinish: true
]

{ #category : 'private' }
AbCritDaemon >> startTimeoutReason [

	| prefix |
	prefix := 'crit did not start within {1} seconds on port {2}'
		format: { self pollBudget asSeconds. self configFile port }.
	^ self firstLogLineSinceSpawn
		  ifNil: [ prefix , ' (the port may be in use by another process)' ]
		  ifNotNil: [ :line | prefix , ': ' , line ]
]

{ #category : 'private' }
AbCritDaemon >> firstLogLineSinceSpawn [

	^ (self logContentsSinceSpawn lines collect: [ :each | each trimBoth ])
		  detect: [ :each | each notEmpty ]
		  ifNone: [ nil ]
]

{ #category : 'private' }
AbCritDaemon >> logContentsSinceSpawn [
	"crit owns the log, so it may have shrunk since the spawn or end in a partial UTF-8 sequence; answer empty then."

	(self logSizeBeforeSpawn notNil and: [ self logFile exists ]) ifFalse: [ ^ '' ].
	^ [ self logFile binaryReadStreamDo: [ :stream |
		    stream position: self logSizeBeforeSpawn.
		    stream upToEnd utf8Decoded ] ]
		  on: Error
		  do: [ '' ]
]

{ #category : 'private' }
AbCritDaemon >> pollBudget [

	^ self pollDelayUntilRunning * self pollAttemptsUntilRunning
]

{ #category : 'private' }
AbCritDaemon >> withLaunchMutexDo: aBlock [

	self class launchMutex critical: aBlock
]

{ #category : 'private' }
AbCritDaemon >> directory [

	^ self topic workingDirectory path
]

{ #category : 'accessing' }
AbCritDaemon >> reviewFinishResultsManager [

	^ AbCritReviewFinishResultsManager default
]

{ #category : 'accessing' }
AbCritDaemon >> configFile [

	^ configFile ifNil: [ configFile := AbCritConfigFile in: self directory ]
]

{ #category : 'accessing' }
AbCritDaemon >> configFile: anAbCritConfigFile [

	configFile := anAbCritConfigFile
]

{ #category : 'testing' }
AbCritDaemon >> isDaemonRunning [

	| json daemon running |
	json := STONJSON fromString: (self runShellCommand: 'crit status --json').
	daemon := json isDictionary ifTrue: [ json at: 'daemon' ifAbsent: [ nil ] ] ifFalse: [ nil ].
	running := daemon isDictionary ifTrue: [ daemon at: 'running' ifAbsent: [ nil ] ] ifFalse: [ nil ].
	^ running ifNil: [ (AbCritError statusUnavailable: 'crit status failed (is crit on PATH?)') signal ]
]

{ #category : 'private' }
AbCritDaemon >> spawn [

	self logFile parent ensureCreateDirectory.
	self logSizeBeforeSpawn: (self logFile exists
			 ifTrue: [ self logFile size ]
			 ifFalse: [ 0 ]).
	self runShellCommand: ('crit --no-open {1} >> {2} 2>&1 &' format: {
			 self networkAccessArguments.
			 self logFile fullName shellQuoted })
]

{ #category : 'private' }
AbCritDaemon >> networkAccessArguments [

	^ AbSettings default critAllowUnauthenticatedNetwork
		  ifTrue: [ '--host 0.0.0.0 --allow-unauthenticated-network' ]
		  ifFalse: [ '--host 127.0.0.1' ]
]

{ #category : 'private' }
AbCritDaemon >> waitUntilRunning [

	1 to: self pollAttemptsUntilRunning do: [ :index |
		([ self isDaemonRunning ] on: Error do: [ false ]) ifTrue: [ ^ true ].
		index = self pollAttemptsUntilRunning ifFalse: [ self pollDelayUntilRunning wait ] ].
	^ false
]

{ #category : 'private' }
AbCritDaemon >> reviewUrlForHost: aHostString [

	^ 'http://{1}:{2}/' format: {
			  self reviewHostFor: aHostString.
			  self configFile port }
]

{ #category : 'private' }
AbCritDaemon >> reviewHostFor: aHostString [

	^ AbSettings default critAllowUnauthenticatedNetwork
		  ifTrue: [ aHostString ]
		  ifFalse: [ 'localhost' ]
]

{ #category : 'private' }
AbCritDaemon >> onFailDo: aFailedBlock reason: aReasonString [

	self topic addSystemMessage: ('Crit review failed: {1} (log: {2})' format: {
				 aReasonString.
				 self logFile fullName }).
	self topic logger warn: { self class name. #startReview. aReasonString }.
	aFailedBlock value: aReasonString
]

{ #category : 'accessing' }
AbCritDaemon >> logFile [

	^ AbSettings defaultAgenticBrowserRootDirectory / '_crit-logs' / (self directory basename , '.log')
]

{ #category : 'command execution' }
AbCritDaemon >> runShellCommand: aCommandString [

	OSSUnixSubprocess new
		shellCommand: aCommandString;
		workingDirectory: self directory fullName;
		redirectStdout;
		runAndWaitOnExitDo: [ :process :stdout :stderr | ^ stdout ifNil: [ '' ] ]
]
