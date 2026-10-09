Class {
	#name : 'AbCritConfigFileTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'root'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbCritConfigFileTest >> setUp [

	super setUp.
	AbSettings initialize.
	root := FileLocator temp / ('ab-crit-cfg-' , UUID new asString36).
	root ensureCreateDirectory
]

{ #category : 'running' }
AbCritConfigFileTest >> tearDown [

	root exists ifTrue: [ root deleteAll ].
	AbSettings initialize.
	super tearDown
]

{ #category : 'private' }
AbCritConfigFileTest >> directoryNamed: aString [

	| dir |
	dir := root / aString.
	dir ensureCreateDirectory.
	^ dir
]

{ #category : 'private' }
AbCritConfigFileTest >> topicAt: aDirectory [

	| topic |
	topic := self newTopic: aDirectory basename.
	topic workingDirectoryPath: aDirectory fullName.
	^ topic
]

{ #category : 'private' }
AbCritConfigFileTest >> writeJson: aDictionary in: aDirectory [

	(aDirectory / '.crit.config.json') writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toString: aDictionary) ]
]

{ #category : 'tests' }
AbCritConfigFileTest >> testPortIsNilWhenFileIsMissing [

	self assert: (AbCritConfigFile in: root) port isNil
]

{ #category : 'tests' }
AbCritConfigFileTest >> testPortIsNilForUnusableValues [

	#( '{"port":0}' '{"port":"9080"}' '{"port":70000}' '{"port":-1}' '{}' 'not-json' '{"port":1.5}' ) do: [ :each |
		(root / '.crit.config.json') ensureDelete.
		(root / '.crit.config.json') writeStreamDo: [ :stream | stream nextPutAll: each ].
		self assert: (AbCritConfigFile in: root) port isNil ]
]

{ #category : 'tests' }
AbCritConfigFileTest >> testPortIsCachedAfterFirstRead [

	| config |
	self writeJson: (Dictionary new at: 'port' put: 9080; yourself) in: root.
	config := AbCritConfigFile in: root.
	self assert: config port equals: 9080.
	self writeJson: (Dictionary new at: 'port' put: 9081; yourself) in: root.
	self assert: config port equals: 9080
]

{ #category : 'tests' }
AbCritConfigFileTest >> testPortIsReadAgainWhileUnassigned [

	| config |
	config := AbCritConfigFile in: root.
	self assert: config port isNil.
	self writeJson: (Dictionary new at: 'port' put: 9080; yourself) in: root.
	self assert: config port equals: 9080
]

{ #category : 'tests' }
AbCritConfigFileTest >> testWritePortUpdatesCachedPort [

	| config |
	config := AbCritConfigFile in: root.
	config writePort: 9080.
	self assert: config port equals: 9080.
	config writePort: 9081.
	self assert: config port equals: 9081
]

{ #category : 'tests' }
AbCritConfigFileTest >> testPortReadsBounds [

	self writeJson: (Dictionary new at: 'port' put: 1; yourself) in: root.
	self assert: (AbCritConfigFile in: root) port equals: 1.
	self writeJson: (Dictionary new at: 'port' put: 65535; yourself) in: root.
	self assert: (AbCritConfigFile in: root) port equals: 65535
]

{ #category : 'tests' }
AbCritConfigFileTest >> testWritePortPreservesOtherKeys [

	| parsed |
	self writeJson: (Dictionary new
		at: 'port' put: 0;
		at: 'no_open' put: true;
		at: 'extra' put: 'keep';
		yourself) in: root.
	(AbCritConfigFile in: root) writePort: 9081.
	parsed := STONJSON fromString: (root / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 9081.
	self assert: (parsed at: 'no_open').
	self assert: (parsed at: 'extra') equals: 'keep'
]

{ #category : 'tests' }
AbCritConfigFileTest >> testWritePortUsesBuiltInDefaultWhenFileIsMissingOrUnreadable [

	| parsed |
	(root / '.crit.config.json') writeStreamDo: [ :stream | stream nextPutAll: 'not-json' ].
	(AbCritConfigFile in: root) writePort: 9080.
	parsed := STONJSON fromString: (root / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 9080.
	self assert: (parsed at: 'no_open').
	self assert: (parsed at: 'ignore_patterns') equals: #( '.crit.config.json' )
]

{ #category : 'tests' }
AbCritConfigFileTest >> testDefaultContentsDescribeAnUnassignedPort [

	| contents |
	contents := AbCritConfigFile defaultContents.
	self assert: (contents at: 'port') equals: 0.
	self assert: (contents at: 'no_open').
	self assert: (contents at: 'ignore_patterns') equals: #( '.crit.config.json' )
]

{ #category : 'private' }
AbCritConfigFileTest >> topicAt: aDirectory critRunning: aBoolean [

	| topic stub |
	topic := self topicAt: aDirectory.
	stub := AbStubCritDaemon forTopic: topic.
	stub commandBlock: [ :command |
		'{"daemon":{"running":' , aBoolean printString , '}}' ].
	topic session critDaemon: stub.
	^ topic
]

{ #category : 'private' }
AbCritConfigFileTest >> topicWithPort: anInteger named: aString critRunning: aBoolean [

	| dir |
	dir := self directoryNamed: aString.
	self writeJson: (Dictionary new at: 'port' put: anInteger; yourself) in: dir.
	^ self topicAt: dir critRunning: aBoolean
]

{ #category : 'private' }
AbCritConfigFileTest >> ensurePortErrorFor: aTopic amongTopics: aTopicCollection [

	^ [
	  AbCritConfigFile ensurePortIn: aTopic workingDirectory amongTopics: aTopicCollection.
	  nil ]
		  on: Error
		  do: [ :ex | ex messageText ]
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortInSkipsPortsOfRunningTopicManagerTopics [

	| held fresh |
	held := self topicWithPort: 9080 named: 'held' critRunning: true.
	fresh := self topicAt: (self directoryNamed: 'fresh').
	AbTopicManager forTest addTopic: held.
	self assert: (AbCritConfigFile ensurePortIn: fresh workingDirectory) equals: 9081
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortCreatesConfigFromDefaultsWhenMissing [

	| dir topic parsed |
	dir := self directoryNamed: 'missing'.
	topic := self topicAt: dir.
	self assert: (AbCritConfigFile ensurePortIn: topic workingDirectory amongTopics: { topic }) equals: 9080.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 9080.
	self assert: (parsed at: 'no_open')
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortKeepsFreeConfiguredPortWithoutWriting [

	| topic file before |
	topic := self topicWithPort: 9085 named: 'own' critRunning: false.
	file := topic workingDirectory path / '.crit.config.json'.
	before := file contents.
	self assert: (AbCritConfigFile ensurePortIn: topic workingDirectory amongTopics: { topic }) equals: 9085.
	self assert: file contents equals: before
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortReassignsPortHeldByRunningTopic [

	| held dir topic parsed |
	held := self topicWithPort: 9080 named: 'held' critRunning: true.
	dir := self directoryNamed: 'clash'.
	self writeJson: (Dictionary new at: 'port' put: 9080; at: 'extra' put: 'stay'; yourself) in: dir.
	topic := self topicAt: dir.
	self assert: (AbCritConfigFile ensurePortIn: topic workingDirectory amongTopics: { held. topic }) equals: 9081.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 9081.
	self assert: (parsed at: 'extra') equals: 'stay'
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortIgnoresPortsOfStoppedTopics [

	| stopped fresh |
	stopped := self topicWithPort: 9080 named: 'stopped' critRunning: false.
	fresh := self topicAt: (self directoryNamed: 'fresh').
	self assert: (AbCritConfigFile ensurePortIn: fresh workingDirectory amongTopics: { stopped. fresh }) equals: 9080
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortCountsStatusErrorsAsStopped [

	| failing fresh |
	failing := self topicWithPort: 9080 named: 'failing' critRunning: true.
	failing critDaemon commandBlock: [ :command | self error: 'crit missing' ].
	fresh := self topicAt: (self directoryNamed: 'fresh').
	self assert: (AbCritConfigFile ensurePortIn: fresh workingDirectory amongTopics: { failing. fresh }) equals: 9080
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortSkipsHandWrittenAndUnreadablePortsOfRunningTopics [

	| broken taken brokenTopic fresh |
	taken := self topicWithPort: 9080 named: 'taken' critRunning: true.
	broken := self directoryNamed: 'broken'.
	(broken / '.crit.config.json') writeStreamDo: [ :stream | stream nextPutAll: '{' ].
	brokenTopic := self topicAt: broken critRunning: true.
	fresh := self topicAt: (self directoryNamed: 'fresh').
	self assert: (AbCritConfigFile
		 ensurePortIn: fresh workingDirectory
		 amongTopics: { taken. brokenTopic. fresh }) equals: 9081
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortSignalsInvalidRangeWithoutWriting [

	| dir topic parsed |
	AbSettings default critPortRange: '9080-'.
	dir := self directoryNamed: 'bad-range'.
	self writeJson: (Dictionary new at: 'port' put: 0; yourself) in: dir.
	topic := self topicAt: dir.
	self assert: (self ensurePortErrorFor: topic amongTopics: { topic }) equals: 'invalid critPortRange: 9080-'.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 0
]

{ #category : 'tests' }
AbCritConfigFileTest >> testEnsurePortSignalsExhaustedRangeWithoutWriting [

	| held dir topic parsed |
	AbSettings default critPortRange: '9080-9080'.
	held := self topicWithPort: 9080 named: 'held' critRunning: true.
	dir := self directoryNamed: 'full'.
	self writeJson: (Dictionary new at: 'port' put: 0; at: 'extra' put: 'stay'; yourself) in: dir.
	topic := self topicAt: dir.
	self
		assert: (self ensurePortErrorFor: topic amongTopics: { held. topic })
		equals: 'crit port range exhausted: 9080-9080'.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 0.
	self assert: (parsed at: 'extra') equals: 'stay'
]
