Class {
	#name : 'AbTopicTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicTest >> setUp [

	AbSettings initialize
]

{ #category : 'tests' }
AbTopicTest >> testAddAiThoughtChunkCreatesThinkMessage [

	| topic |
	topic := AbTopic new.
	topic addAiThoughtChunk: 'Let me think...'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Let me think...'.
	self assert: topic messages last isThink
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkAppendsToExistingAiMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	topic addAiTextChunk: ' world'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last text equals: 'Hello world'
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkDoesNotAppendToThinkMessage [

	| topic |
	topic := AbTopic new.
	topic addAiThoughtChunk: 'Thinking...'.
	topic addAiTextChunk: 'Response text'.
	self assert: topic messages size equals: 2.
	self assert: topic messages first text equals: 'Thinking...'.
	self assert: topic messages first isThink.
	self assert: topic messages second text equals: 'Response text'.
	self deny: topic messages second isThink
]

{ #category : 'tests' }
AbTopicTest >> testAddAiTextChunkCreatesMessage [

	| topic |
	topic := AbTopic new.
	topic addAiTextChunk: 'Hello'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #ai.
	self assert: topic messages last text equals: 'Hello'
]

{ #category : 'tests' }
AbTopicTest >> testAddApprovalRequestAddsMessage [

	| topic msg |
	topic := AbTopic new.
	msg := topic addApprovalRequest: 'May I delete files?'.
	self assert: topic messages size equals: 1.
	self assert: msg isApprovalRequest.
]

{ #category : 'tests' }
AbTopicTest >> testDoneToWorkingOnNewPrompt [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testEndedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	self assert: topic status equals: #endTurn
]

{ #category : 'tests' }
AbTopicTest >> testHumanRespondedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	topic stateMachine handleEvent: #humanResponded.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testInitialStatus [

	self assert: AbTopic new status equals: #initial
]

{ #category : 'tests' }
AbTopicTest >> testHasPendingApprovalRequest [

	| topic |
	topic := AbTopic new.
	self deny: topic hasPendingApprovalRequest.
	topic addApprovalRequest: 'Approve?'.
	self assert: topic hasPendingApprovalRequest
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransitionFromIdle [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testPermissionRequestedTransitionFromDone [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	topic stateMachine handleEvent: #permissionRequested.
	self assert: topic status equals: #waitingForHuman
]

{ #category : 'tests' }
AbTopicTest >> testImportGuardNestingCounter [

	| topic workDir |
	topic := AbTopic new.
	workDir := topic workingDirectory.
	self deny: workDir isImportingFromSource.
	workDir beginImportFromSource.
	self assert: workDir isImportingFromSource.
	workDir beginImportFromSource.
	workDir endImportFromSource.
	self assert: workDir isImportingFromSource.
	workDir endImportFromSource.
	self deny: workDir isImportingFromSource
]

{ #category : 'tests' }
AbTopicTest >> testPromptSentTransition [

	| topic |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalAllowAlways [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I modify DBAdapter?'.
	topic messages add: msg.
	topic resolveApproval: 'yes'.
	self assert: msg approvalResponse equals: #allowAlways.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testResolveApprovalRejectOnce [

	| topic msg |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #permissionRequested.
	msg := AbMessage approvalRequestText: 'May I delete files?'.
	topic messages add: msg.
	topic resolveApproval: 'no'.
	self assert: msg approvalResponse equals: #rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testRequestApprovalReturnsResolvedResponse [

	| topic response done |
	topic := AbTopic new.
	done := Semaphore new.
	[
	response := topic requestApproval: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApproval: 'yes'.
	done waitTimeoutMilliseconds: 1000.
	self assert: response equals: #allowAlways
]

{ #category : 'tests' }
AbTopicTest >> testRequestApprovalFromIdleTransitionsToDone [

	| topic response done |
	topic := AbTopic new.
	done := Semaphore new.
	[
	response := topic requestApproval: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApproval: 'yes'.
	done waitTimeoutMilliseconds: 1000.
	self assert: response equals: #allowAlways.
	self assert: topic status equals: #endTurn
]

{ #category : 'tests' }
AbTopicTest >> testRequestApprovalFromDoneTransitionsToWorking [

	| topic response done |
	topic := AbTopic new.
	topic stateMachine handleEvent: #promptSent.
	topic stateMachine handleEvent: #turnEnded.
	done := Semaphore new.
	[
	response := topic requestApproval: 'Approve this action?'.
	done signal ] fork.
	[ topic hasPendingApprovalRequest ] whileFalse: [
		(Delay forMilliseconds: 1) wait ].
	topic resolveApproval: 'yes'.
	done waitTimeoutMilliseconds: 1000.
	self assert: response equals: #allowAlways.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testRequestApprovalTimesOutAndRejects [

	| topic response done timedOut |
	topic := AbTopic new.
	AbSettings default approvalWaitTimeoutSeconds: 0.
	topic stateMachine handleEvent: #promptSent.
	done := Semaphore new.
	[
	response := topic requestApproval: 'Approve this action?'.
	done signal ] fork.
	timedOut := done waitTimeoutMilliseconds: 200.
	timedOut ifTrue: [
		topic resolveApproval: 'no'.
		done waitTimeoutMilliseconds: 200 ].
	self deny: timedOut.
	self assert: response equals: #rejectOnce.
	self assert: topic status equals: #working
]

{ #category : 'tests' }
AbTopicTest >> testStatusChangedAnnouncementFired [

	| topic statusChanges |
	topic := AbTopic new.
	statusChanges := OrderedCollection new.
	topic announcer
		when: AbTopicStatusChanged
		do: [ :ann | statusChanges add: ann topic status ]
		for: self.
	[ topic stateMachine handleEvent: #promptSent.
	self assert: (statusChanges includes: #working) ]
		ensure: [ topic announcer unsubscribe: self ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesProvidedPathWhenSet [

	| topic customPath |
	topic := AbTopic new.
	customPath := (FileLocator temp / ('ab-topic-custom-' , UUID new asString36))
		              fullName.
	topic workingDirectoryPath: customPath.
	self assert: topic workingDirectoryPath equals: customPath
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathLoadsSrcDirectoryFromProject [

	| topic dir |
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	(dir / '.project') writeStreamDo: [ :s |
		s nextPutAll: '{''srcDirectory'' : ''source''}' ].
	[
		topic := AbTopic new.
		topic workingDirectoryPath: dir fullName.
		self assert: topic workingDirectory srcDirectory equals: 'source'.
		self
			assert: topic workingDirectory sourcePath fullName
			equals: dir fullName , '/source' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesDefaultSrcWhenProjectMissing [

	| topic dir |
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	[
		topic := AbTopic new.
		topic workingDirectoryPath: dir fullName.
		self assert: topic workingDirectory srcDirectory equals: 'src' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathResetsWorkingDirectoryInstance [

	| topic firstWorkDir dir |
	topic := AbTopic new.
	firstWorkDir := topic workingDirectory.
	dir := FileLocator temp / ('ab-topic-src-' , UUID new asString36).
	dir ensureCreateDirectory.
	(dir / '.project') writeStreamDo: [ :s |
		s nextPutAll: '{''srcDirectory'' : ''source''}' ].
	[
		topic workingDirectoryPath: dir fullName.
		self deny: topic workingDirectory == firstWorkDir.
		self assert: topic workingDirectory srcDirectory equals: 'source' ]
		ensure: [ dir deleteAll ]
]

{ #category : 'tests' }
AbTopicTest >> testWorkingDirectoryPathUsesGeneratedPathByDefault [

	| topic expectedPath |
	topic := AbTopic new title: 'Topic Name'.
	expectedPath := (Smalltalk imageDirectory / 'agentic-browser'
	                 / topic workingDirectory directoryName) fullName.
	self assert: topic workingDirectoryPath equals: expectedPath
]
