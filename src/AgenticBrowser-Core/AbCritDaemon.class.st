"
I am the crit review daemon for one topic's working directory.

Responsibility:
- I decide whether crit review is available, and why a start must be refused.
- I start or reuse the detached crit daemon and report one system message plus one callback.
- Before spawning, I ensure the working directory has a crit port no other running crit holds, creating .crit.config.json when it is missing.
- I serialize all starts, across directories, so overlapping starts spawn once and never pick the same port.
- I never stop crit, and I never signal to my caller.

Collaborators:
- AbTopic: I read its working directory, status, and logger, and I post the review message on it.
- AbCritConfigFile: I ask it to ensure the port before spawning, and read the port through one cached instance.
- AbTopicSession: It caches me, one per topic.
- AbSettings: I read #useCrit and the crit log directory.
- AbStubCritDaemon: Tests override #runShellCommand: so no process is spawned.

Public API and Key Messages:
- AbCritDaemon class>>forTopic: - Daemon for one topic.
- #isAvailable / #unavailableReason / #refusalReasonOnStart - Whether the control is shown (useCrit and .git) and whether a start may proceed.
- #isDaemonRunning - Whether crit status reports a running daemon; signals an Error when the status cannot be read.
- #startReviewForHost:ifStarted:ifFailed: - Synchronous start. ifStarted: receives the url and port. ifFailed: receives the reason.

Internal Representation:
- topic - The AbTopic whose working directory crit serves.
- configFile - Lazily created AbCritConfigFile for the working directory; reset before ensuring the port so the file is read again.
- pollAttemptsUntilRunning / pollDelayUntilRunning - How many status checks to make, and the pause between them. Defaults are 20 and 500 ms.
- launchMutex (class) - One Mutex for all directories, covering status, port selection, spawn, and poll.
"
Class {
	#name : 'AbCritDaemon',
	#superclass : 'Object',
	#instVars : [
		'topic',
		'configFile',
		'pollAttemptsUntilRunning',
		'pollDelayUntilRunning'
	],
	#classInstVars : [
		'launchMutex'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
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
		  self topic isInitial ifTrue: [ 'topic status is initial' ] ]
]

{ #category : 'operations' }
AbCritDaemon >> startReviewForHost: aHostString ifStarted: started ifFailed: failed [

	[ (self class isValidReviewHost: aHostString) ifFalse: [
		  ^ self fail: 'invalid host' with: failed ].
	self refusalReasonOnStart ifNotNil: [ :reason | ^ self fail: reason with: failed ].
	self withLaunchMutexDo: [
		self launchForHost: aHostString ifStarted: started ifFailed: failed ] ]
		on: Error
		do: [ :ex | self fail: ex messageText with: failed ]
]

{ #category : 'private' }
AbCritDaemon >> launchForHost: aHostString ifStarted: started ifFailed: failed [

	| running url |
	running := [ self isDaemonRunning ] on: Error do: [ nil ].
	running ifNil: [ ^ self fail: 'crit status failed (is crit on PATH?)' with: failed ].
	running ifFalse: [
		self ensurePort.
		[ self spawn ] on: Error do: [ :ex | ^ self fail: ex messageText with: failed ].
		self waitUntilRunning ifFalse: [
			^ self fail: self startTimeoutReason with: failed ] ].
	url := self reviewUrlForHost: aHostString.
	self topic addSystemMessage: 'Crit review: ' , url.
	started value: url value: self configFile port
]

{ #category : 'private' }
AbCritDaemon >> ensurePort [

	self configFile: nil.
	AbCritConfigFile ensurePortIn: self topic workingDirectory
]

{ #category : 'private' }
AbCritDaemon >> startTimeoutReason [

	^ 'crit did not start within {1} seconds on port {2} (the port may be in use by another process)'
		format: { self pollBudget asSeconds. self configFile port }
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
	^ running ifNil: [ self error: 'crit status failed (is crit on PATH?)' ]
]

{ #category : 'private' }
AbCritDaemon >> spawn [

	self logFile parent ensureCreateDirectory.
	self runShellCommand: 'crit --no-open --host 0.0.0.0 --allow-unauthenticated-network >> '
		, (self shellQuoted: self logFile fullName) , ' 2>&1 &'
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
			  aHostString.
			  self configFile port }
]

{ #category : 'private' }
AbCritDaemon >> fail: aReasonString with: aReasonBlock [

	self topic addSystemMessage: ('Crit review failed: {1} (log: {2})' format: {
				 aReasonString.
				 self logFile fullName }).
	self topic logger warn: { self class name. #startReview. aReasonString }.
	aReasonBlock value: aReasonString
]

{ #category : 'accessing' }
AbCritDaemon >> logFile [

	^ AbSettings defaultAgenticBrowserRootDirectory / 'crit-logs' / (self directory basename , '.log')
]

{ #category : 'private' }
AbCritDaemon >> shellQuoted: aString [

	^ String streamContents: [ :stream |
		  stream nextPut: $'.
		  aString do: [ :char |
			  char = $'
				  ifTrue: [ stream nextPutAll: '''\''''' ]
				  ifFalse: [ stream nextPut: char ] ].
		  stream nextPut: $' ]
]

{ #category : 'command execution' }
AbCritDaemon >> runShellCommand: aCommandString [

	OSSUnixSubprocess new
		shellCommand: aCommandString;
		workingDirectory: self directory fullName;
		redirectStdout;
		runAndWaitOnExitDo: [ :process :stdout :stderr | ^ stdout ifNil: [ '' ] ]
]
