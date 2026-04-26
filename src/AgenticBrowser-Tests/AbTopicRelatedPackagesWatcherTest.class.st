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
	topic workingDirectory isImporting: true.
	[ watcher handleClassChange: ann ]
		on: Error
		do: [ :e | errorRaised := true ].
	self deny: errorRaised
]

{ #category : 'tests' }
AbTopicRelatedPackagesWatcherTest >> testHandleMethodChangeSuppressedDuringImport [

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
