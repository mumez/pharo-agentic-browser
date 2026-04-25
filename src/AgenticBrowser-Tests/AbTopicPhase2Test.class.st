Class {
	#name : 'AbTopicPhase2Test',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicPhase2Test >> testAddSystemMessage [

	| topic |
	topic := AbTopic new.
	topic addSystemMessage: 'Export complete'.
	self assert: topic messages size equals: 1.
	self assert: topic messages last sender equals: #system.
	self assert: topic messages last text equals: 'Export complete'
]

{ #category : 'tests' }
AbTopicPhase2Test >> testImageWatcherLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic imageWatcher isKindOf: AbImageWatcher)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesEmptyPrefix [

	| topic |
	topic := AbTopic new.
	topic packagePrefix: ''.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesNilPrefix [

	| topic |
	topic := AbTopic new.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesWithPrefix [

	| topic names |
	topic := AbTopic new.
	topic packagePrefix: 'AgenticBrowser-*'.
	names := topic matchingPackageNames.
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Core' ])
]

{ #category : 'tests' }
AbTopicPhase2Test >> testPackagePrefixDefaultsToNil [

	self assert: AbTopic new packagePrefix isNil
]

{ #category : 'tests' }
AbTopicPhase2Test >> testSetPackagePrefix [

	| topic |
	topic := AbTopic new.
	topic packagePrefix: 'ACP-*'.
	self assert: topic packagePrefix equals: 'ACP-*'
]

{ #category : 'tests' }
AbTopicPhase2Test >> testStartWatchingAndStop [

	| topic |
	topic := AbTopic new.
	topic startWatching.
	self assert: topic imageWatcher isWatching.
	topic stopWatching.
	self deny: topic imageWatcher isWatching
]

{ #category : 'tests' }
AbTopicPhase2Test >> testTopicIdIsGeneratedOnInit [

	| topic |
	topic := AbTopic new.
	self assert: topic topicId notNil.
	self assert: topic topicId isString.
	self assert: topic topicId notEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testTopicIdIsUniquePerTopic [

	self deny: AbTopic new topicId equals: AbTopic new topicId
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
AbTopicPhase2Test >> testWorkingDirectoryWasCreatedForConnection [

	| topic path |
	topic := AbTopic new title: 'money calc'.
	path := topic workingDirectory path.
	self deny: path exists.
	self deny: topic imageWatcher isWatching.
	topic ensureWorkingDirectoryForConnection.
	self assert: path exists.
	self assert: topic imageWatcher isWatching.
	topic stopWatching.
	path deleteAll
]
