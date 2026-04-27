Class {
	#name : 'AbSettingsTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbSettingsTest >> setUp [

	AbSettings initialize
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultCopiedDoesNotMutateDefault [

	| copied |
	copied := AbSettings defaultCopied.
	copied watcherMessageThrottleDuration: 5 seconds.
	self assert: AbSettings default watcherMessageThrottleDuration equals: 2 seconds
]

{ #category : 'tests' }
AbSettingsTest >> testDefaultReturnsSingletonInstance [

	self assert: AbSettings default == AbSettings default
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleDurationDefault [

	self assert: AbSettings default watcherMessageThrottleDuration equals: 2 seconds
]

{ #category : 'tests' }
AbSettingsTest >> testWatcherMessageThrottleDurationSettable [

	AbSettings default watcherMessageThrottleDuration: 7 seconds.
	self assert: AbSettings default watcherMessageThrottleDuration equals: 7 seconds
]
