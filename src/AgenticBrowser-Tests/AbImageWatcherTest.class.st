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
AbImageWatcherTest >> testHandleClassChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := ClassModifiedClassDefinition new.
	ann newClassDefinition: AbTopic.
	topic workingDirectory isImporting: true.
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbImageWatcherTest >> testHandleMethodChangeSuppressedDuringImport [

	| ann errorRaised |
	errorRaised := false.
	ann := MethodModified new.
	ann method: (AbTopic >> #status).
	topic workingDirectory isImporting: true.
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
