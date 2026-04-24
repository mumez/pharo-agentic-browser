Class {
	#name : 'AbImageWatcherTest',
	#superclass : 'TestCase',
	#instVars : [
		'topic',
		'watcher'
	],
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
AbImageWatcherTest >> testHandleClassChangeIgnoresUnwatchedPackage [

	| ann errorRaised |
	errorRaised := false.
	"ClassModifiedClassDefinition has no classAffected: setter;
	 newClassDefinition: sets the class returned by classAffected.
	 The handler calls anAnnouncement classAffected package name,
	 so we must use newClassDefinition: to populate classAffected."
	ann := ClassModifiedClassDefinition new.
	ann newClassDefinition: AbTopic.
	"topic watchedPackages is empty, so the handler calls classAffected package name
	 and then returns early — no workingDirectory access should occur"
	topic watchedPackages add: 'SomeOtherPackage'.
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
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
