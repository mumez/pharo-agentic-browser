"
I am the crit review daemon for one topic's working directory.

Responsibility:
- I decide whether crit review is available, and why a start must be refused.
- I start or reuse the detached crit daemon and report one system message plus one callback.
- I serialize overlapping starts for the same directory so only one spawn runs.
- I never stop crit, and I never signal to my caller.

Collaborators:
- AbTopic: I read its working directory, status, and logger, and I post the review message on it.
- AbCritConfigFile: I read the assigned port through one cached instance.
- AbTopicSession: It caches me so repeated availability checks reuse my config file.
- AbSettings: I read #useCrit and the crit log directory.
- AbStubCritDaemon: Tests override #runShellCommand: so no process is spawned.

Public API and Key Messages:
- AbCritDaemon class>>forTopic: - Daemon for one topic.
- #isAvailable / #unavailableReason / #refusalReasonOnStart - Whether the control is shown and whether a start may proceed.
- #startReviewForHost:ifStarted:ifFailed: - Synchronous start. ifStarted: receives the url and port. ifFailed: receives the reason.

Internal Representation:
- topic - The AbTopic whose working directory crit serves.
- configFile - Lazily created AbCritConfigFile for the working directory.
- pollAttemptsUntilRunning / pollDelayUntilRunning - How many status checks to make, and the pause between them. Defaults are 20 and 500 ms.
- launchMutexes (class) - One Mutex per working-directory path, covering status, spawn, and poll.
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
		'launchMutexes',
		'launchMutexRegistryMutex'
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

	self resetLaunchMutexes
]

{ #category : 'private' }
AbCritDaemon class >> launchMutexes [

	^ launchMutexes ifNil: [ launchMutexes := Dictionary new ]
]

{ #category : 'private' }
AbCritDaemon class >> launchMutexRegistryMutex [

	^ launchMutexRegistryMutex ifNil: [ launchMutexRegistryMutex := Mutex new ]
]

{ #category : 'private' }
AbCritDaemon class >> launchMutexFor: aDirectoryFullName [

	^ self launchMutexRegistryMutex critical: [
		  self launchMutexes at: aDirectoryFullName ifAbsentPut: [ Mutex new ] ]
]

{ #category : 'private' }
AbCritDaemon class >> resetLaunchMutexes [

	launchMutexes := nil.
	launchMutexRegistryMutex := nil
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
	self configFile port ifNil: [ ^ 'no crit port assigned' ].
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
		[ self spawn ] on: Error do: [ :ex | ^ self fail: ex messageText with: failed ].
		self waitUntilRunning ifFalse: [
			^ self fail: 'crit did not start within 10 seconds' with: failed ] ].
	url := self reviewUrlForHost: aHostString.
	self topic addSystemMessage: 'Crit review: ' , url.
	started value: url value: self configFile port
]

{ #category : 'private' }
AbCritDaemon >> withLaunchMutexDo: aBlock [

	(self class launchMutexFor: self directory fullName) critical: aBlock
]

{ #category : 'private' }
AbCritDaemon >> directory [

	^ self topic workingDirectory path
]

{ #category : 'accessing' }
AbCritDaemon >> configFile [

	^ configFile ifNil: [ configFile := AbCritConfigFile in: self directory ]
]

{ #category : 'private' }
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
