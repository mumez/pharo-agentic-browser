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
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann newClassDefinition: AbTopic.
	topic workingDirectory beginImportFromSource.
	[
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ] ]
		ensure: [ topic workingDirectory endImportFromSource ].
	self deny: errorRaised
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
AbTopicRelatedPackagesWatcherTest >> testIsWatchingInitiallyFalse [

	self deny: watcher isWatching
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
		(watcher shouldProceedWithExportForApprovalResponse: #allowAlways).
	self deny:
		(watcher shouldProceedWithExportForApprovalResponse: #rejectOnce)
]
