Class {
	#name : 'AbWorkingDirectoryTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbWorkingDirectoryTest >> testEnsureExists [

	| topic workDir |
	topic := AbTopic new title: 'Test-WD-Creation'.
	workDir := AbWorkingDirectory forTopic: topic.
	workDir ensureExists.
	self assert: workDir path exists.
	workDir path deleteAll
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testPath [

	| topic workDir |
	topic := AbTopic new title: 'DB Optimization'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: (workDir path fullName includesSubstring: 'agentic-browser').
	self assert: (workDir path fullName includesSubstring: 'DB-Optimization')
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameEmptyFallback [

	| topic workDir |
	topic := AbTopic new title: ''.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpaces [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Topic'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'My-Cool-Topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpecialChars [

	| topic workDir |
	topic := AbTopic new title: 'DB/Schema: v2'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: (workDir safeTopicName includesSubstring: '/').
	self deny: (workDir safeTopicName includesSubstring: ':')
]
