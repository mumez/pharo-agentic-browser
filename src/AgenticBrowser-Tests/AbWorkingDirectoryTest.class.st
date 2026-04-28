Class {
	#name : 'AbWorkingDirectoryTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsSafeTopicName [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: (workDir directoryName includesSubstring: 'My-Cool-Feature')
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testDirectoryNameContainsTopicIdPrefix [

	| topic workDir expectedIdPrefix |
	topic := AbTopic new title: 'My Cool Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	expectedIdPrefix := topic topicId copyFrom: 1 to: 8.
	self assert: (workDir directoryName includesSubstring: expectedIdPrefix)
]

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
AbWorkingDirectoryTest >> testIsImportingInitiallyFalse [

	| topic workDir |
	topic := AbTopic new title: 'Test'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: workDir isImporting
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testNewTopicWorkingDirectoryDoesNotExist [

	"A freshly-created topic must have no working directory on disk yet.
	 This is the precondition for auto-export when a package prefix is first set."

	| topic workDir |
	topic := AbTopic new title: 'Brand-New-Topic'.
	workDir := AbWorkingDirectory forTopic: topic.
	self deny: workDir path exists
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testPathIsInsideAgenticBrowserSubdir [

	| topic workDir |
	topic := AbTopic new title: 'My Feature'.
	workDir := AbWorkingDirectory forTopic: topic.
	self
		assert: workDir path parent fullName
		equals: (Smalltalk imageDirectory / 'agentic-browser') fullName
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testImportPackageUsesAbSisServerCurrent [

	| topic workDir stub result path |
	topic := AbTopic new title: 'Server Routing'.
	path := (FileLocator temp / ('ab-working-dir-' , UUID new asString36)) fullName.
	topic workingDirectoryPath: path.
	workDir := AbWorkingDirectory forTopic: topic.
	stub := AbSisServerStub new.
	[
	AbSisServer current: stub.
	result := workDir importPackage: 'AgenticBrowser-Core'.
	self assert: result equals: 'stub-import'.
	self assert: (stub lastRequest at: 'package_name') equals: 'AgenticBrowser-Core' ]
		ensure: [ AbSisServer current: nil ]
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameEmptyFallback [

	| topic workDir |
	topic := AbTopic new title: ''.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'topic'
]

{ #category : 'tests' }
AbWorkingDirectoryTest >> testSafeTopicNameReplacesSpecialChars [

	| topic workDir |
	topic := AbTopic new title: 'My Cool Topic!'.
	workDir := AbWorkingDirectory forTopic: topic.
	self assert: workDir safeTopicName equals: 'My-Cool-Topic-'
]
