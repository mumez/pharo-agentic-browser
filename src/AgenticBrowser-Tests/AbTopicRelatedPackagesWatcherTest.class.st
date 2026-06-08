Class {
	#name : 'AbTopicRelatedPackagesWatcherTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'topic',
		'watcher'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicRelatedPackagesWatcherTest >> setUp [

	super setUp.

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
AbTopicRelatedPackagesWatcherTest >> testStopTerminatesWorkerProcess [

	| process |
	watcher start.
	process := watcher workerProcess.
	watcher stop.
	self assert: process isTerminated.
	self assert: watcher workerProcess isNil
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testNormalizedClassNameStripsClassSuffix [

	self
		assert: (watcher normalizedClassNameFrom: 'SomeClass class')
		equals: 'SomeClass'
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testNormalizedClassNameLeavesInstanceNameUnchanged [

	self
		assert: (watcher normalizedClassNameFrom: 'SomeClass')
		equals: 'SomeClass'
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeNamedEnqueuesItem [

	watcher handleClassChangeNamed: 'MyClass' in: 'MyPkg'.
	self assert: watcher changeQueue size equals: 1.
	self assert: watcher changeQueue next equals: 'MyClass' -> 'MyPkg'
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleClassChangeNamedEnqueuesInFifoOrder [

	watcher handleClassChangeNamed: 'ClassA' in: 'Pkg1'.
	watcher handleClassChangeNamed: 'ClassB' in: 'Pkg2'.
	self assert: watcher changeQueue next equals: 'ClassA' -> 'Pkg1'.
	self assert: watcher changeQueue next equals: 'ClassB' -> 'Pkg2'
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testIsApprovalThrottledWhenWithinWindow [

	watcher lastApprovalGrantedAtByPackage at: 'MyPkg' put: DateAndTime now.
	self assert: (watcher isApprovalThrottledFor: 'MyPkg')
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testIsApprovalThrottledFalseWhenWindowExpired [

	watcher lastApprovalGrantedAtByPackage
		at: 'MyPkg'
		put: DateAndTime now - watcher messageThrottleDuration - 1 second.
	self deny: (watcher isApprovalThrottledFor: 'MyPkg')
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testIsApprovalThrottledFalseWhenNeverGranted [

	self deny: (watcher isApprovalThrottledFor: 'MyPkg')
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testDoubleStartDoesNotLeakProcess [

	| firstProcess |
	watcher start.
	firstProcess := watcher workerProcess.
	watcher start.
	self assert: watcher workerProcess identicalTo: firstProcess
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testDoubleStopDoesNotError [

	watcher start.
	watcher stop.
	self shouldnt: [ watcher stop ] raise: Error.
	self deny: watcher isWatching.
	self assert: watcher workerProcess isNil
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testStopTerminatesWorkerProcess [

	| process |
	watcher start.
	process := watcher workerProcess.
	watcher stop.
	self assert: process isTerminated.
	self assert: watcher workerProcess isNil
]
