Class {
	#name : 'AbTopicPhase2Test',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicPhase2Test >> tearDown [

	"Ensure any watcher started in tests is cleaned up."
	super tearDown
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddWatchedPackage [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	self assert: (topic watchedPackages includes: 'AgenticBrowser-Core')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddWatchedPackageNoDuplicates [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	self assert: topic watchedPackages size equals: 1
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemoveWatchedPackage [

	| topic |
	topic := AbTopic new.
	topic addWatchedPackage: 'AgenticBrowser-Core'.
	topic removeWatchedPackage: 'AgenticBrowser-Core'.
	self deny: (topic watchedPackages includes: 'AgenticBrowser-Core')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemoveWatchedPackageAbsent [

	| topic |
	topic := AbTopic new.
	"Should not raise an error"
	[ topic removeWatchedPackage: 'NonExistent' ] on: Error do: [ :e | self fail ]
]

{ #category : 'tests' }
AbTopicPhase2Test >> testWorkingDirectoryLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic workingDirectory isKindOf: AbWorkingDirectory)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testWorkingDirectoryReturnsSameInstance [

	| topic |
	topic := AbTopic new.
	self assert: topic workingDirectory == topic workingDirectory
]

{ #category : 'tests' }
AbTopicPhase2Test >> testStartWatchingAndStop [

	| topic |
	topic := AbTopic new.
	topic startWatching.
	[ self assert: topic imageWatcher isWatching ] ensure: [ topic stopWatching ].
	self deny: topic imageWatcher isWatching
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddSystemMessage [

	| topic |
	topic := AbTopic new.
	topic addSystemMessage: 'Export complete'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: topic messages last text equals: 'Export complete'
]
