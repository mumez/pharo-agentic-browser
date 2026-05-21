Class {
	#name : 'AbTopicRelatedPackagesWatcherTest',
	#superclass : 'TestCase',
	#instVars : [
		'topic',
		'watcher'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicRelatedPackagesWatcherTest >> setUp [

	topic := AbTopic new.
	watcher := AbTopicRelatedPackagesWatcher forTopic: topic
]

{ #category : 'running' }
AbTopicRelatedPackagesWatcherTest >> tearDown [

	watcher stop.
	super tearDown
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleMethodChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	topic workingDirectory beginImportFromSource.
	[
	[ watcher handleMethodChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ] ]
		ensure: [ topic workingDirectory endImportFromSource ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleMethodChangeSuppressedDuringSourceImport [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	topic workingDirectory beginImportFromSource.
	[
	[ watcher handleMethodChange: ann ]
			on: Error
			do: [ :e | errorRaised := true ] ]
		ensure: [ topic workingDirectory endImportFromSource ].
	self deny: errorRaised.
	self deny: topic hasPendingApprovalRequest
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandlePackageChangeForExternalPackageTracksWithoutApproval [

	watcher handlePackageChange: 'External-Changed'.
	(Delay forMilliseconds: 100) wait.
	self deny: topic hasPendingApprovalRequest.
	self
		assert: (topic messages select: [ :m | m isApprovalRequest ]) isEmpty.
	self
		assert: (topic updatedExternalPackageNames includes: 'External-Changed')
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandlePackageChangePreventsDoubleApprovalRequest [

	"Without fork, each handlePackageChange: call runs synchronously.
	The first call requests approval and completes before the second call.
	Each call independently requests approval, so we verify that
	multiple calls each produce their own approval request."
	AbSettings default exportApprovalWaitTimeoutSeconds: 0.
	topic packagePrefixes: #( 'MyPkg' ).
	watcher handlePackageChange: 'MyPkg'.
	watcher handlePackageChange: 'MyPkg'.
	"Each synchronous call produces an approval request"
	self
		assert: (topic messages select: [ :m | m isApprovalRequest ]) size
		equals: 2
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testIsWatchingInitiallyFalse [

	self deny: watcher isWatching
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testShouldAnnouncePackageChangeAllowsDifferentPackages [

	| now |
	now := DateAndTime now.
	self assert: (watcher shouldAnnouncePackageChangeFor: 'Pkg-A' at: now).
	self assert: (watcher shouldAnnouncePackageChangeFor: 'Pkg-B' at: now)
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testShouldAnnouncePackageChangeAllowsWhenWindowPassed [

	| now later |
	now := DateAndTime now.
	later := now + watcher messageThrottleDuration + 1 second.
	self assert: (watcher shouldAnnouncePackageChangeFor: 'Pkg-A' at: now).
	self assert: (watcher shouldAnnouncePackageChangeFor: 'Pkg-A' at: later)
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testShouldAnnouncePackageChangeSuppressesWithinThrottleWindow [

	| now |
	now := DateAndTime now.
	self assert: (watcher shouldAnnouncePackageChangeFor: 'Pkg-A' at: now).
	self deny:
		(watcher
			 shouldAnnouncePackageChangeFor: 'Pkg-A'
			 at: now + (watcher messageThrottleDuration / 2))
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testShouldProceedWithExportForApprovalResponse [

	self assert:
		(watcher shouldProceedWithExportForApprovalResponse: AbConstants allowOnce).
	self assert:
		(watcher shouldProceedWithExportForApprovalResponse: AbConstants allowAlways).
	self deny:
		(watcher shouldProceedWithExportForApprovalResponse: AbConstants rejectOnce)
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStartSetsIsWatching [

	watcher start.
	self assert: watcher isWatching
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStopClearsIsWatching [

	watcher start.
	watcher stop.
	self deny: watcher isWatching
]
