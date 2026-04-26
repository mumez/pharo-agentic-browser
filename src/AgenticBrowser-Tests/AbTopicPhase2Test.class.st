Class {
	#name : 'AbTopicPhase2Test',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbTopicPhase2Test >> testAddPackagePrefix [

	| topic |
	topic := AbTopic new.
	topic addPackagePrefix: 'ACP-*'.
	topic addPackagePrefix: 'BaselineOfACP'.
	self assert: topic packagePrefixes size equals: 2.
	self assert: (topic hasPackagePrefix: 'ACP-*').
	self assert: (topic hasPackagePrefix: 'BaselineOfACP')
]

{ #category : 'tests' }
AbTopicPhase2Test >> testAddPackagePrefixIgnoresDuplicate [

	| topic |
	topic := AbTopic new.
	topic addPackagePrefix: 'ACP-*'.
	topic addPackagePrefix: 'ACP-*'.
	self assert: topic packagePrefixes size equals: 1
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

{ #category : 'tests' }
AbTopicPhase2Test >> testImageWatcherLazyInit [

	| topic |
	topic := AbTopic new.
	self assert: (topic imageWatcher isKindOf: AbTopicRelatedPackagesWatcher)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesEmptyPrefixes [

	| topic |
	topic := AbTopic new.
	self assert: topic matchingPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesMultiplePrefixes [

	| topic names |
	topic := AbTopic new.
	topic addPackagePrefix: 'AgenticBrowser-*'.
	topic addPackagePrefix: 'BaselineOfAgenticBrowser'.
	names := topic matchingPackageNames.
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Core' ]).
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Tests' ])
]

{ #category : 'tests' }
AbTopicPhase2Test >> testMatchingPackageNamesWithPrefix [

	| topic names |
	topic := AbTopic new.
	topic addPackagePrefix: 'AgenticBrowser-*'.
	names := topic matchingPackageNames.
	self assert: (names anySatisfy: [ :n | n = 'AgenticBrowser-Core' ])
]

{ #category : 'tests' }
AbTopicPhase2Test >> testPackagePrefixesDefaultsToEmptySet [

	self assert: AbTopic new packagePrefixes isEmpty.
	self assert: (AbTopic new packagePrefixes isKindOf: Set)
]

{ #category : 'tests' }
AbTopicPhase2Test >> testRemovePackagePrefix [

	| topic |
	topic := AbTopic new.
	topic addPackagePrefix: 'ACP-*'.
	topic removePackagePrefix: 'ACP-*'.
	self deny: (topic hasPackagePrefix: 'ACP-*')
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
