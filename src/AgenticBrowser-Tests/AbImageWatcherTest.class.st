Class {
	#name : 'AbImageWatcherTest',
	#superclass : 'TestCase',
	#instVars : [ 'topic', 'watcher' ],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbImageWatcherTest >> setUp [

	topic := AbTopic new.
	watcher := AbImageWatcher forTopic: topic
]

{ #category : 'running' }
AbImageWatcherTest >> tearDown [

	watcher stop.
	super tearDown
]

{ #category : 'tests' }
AbImageWatcherTest >> testIsWatchingInitiallyFalse [

	self deny: watcher isWatching
]

{ #category : 'tests' }
AbImageWatcherTest >> testStartSetsIsWatching [

	watcher start.
	self assert: watcher isWatching
]

{ #category : 'tests' }
AbImageWatcherTest >> testStopClearsIsWatching [

	watcher start.
	watcher stop.
	self deny: watcher isWatching
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleMethodChangeIgnoresUnwatchedPackage [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	"watchedPackages is empty so handler should return early without accessing workingDirectory"
	[ watcher handleMethodChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleClassChangeIgnoresUnwatchedPackage [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann newClassDefinition: AbTopic.
	"watchedPackages is empty so handler should return early without accessing workingDirectory"
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]
