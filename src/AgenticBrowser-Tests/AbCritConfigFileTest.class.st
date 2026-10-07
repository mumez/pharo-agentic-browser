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

	| parsed |
	parsed := STONJSON fromString: AbCritConfigFile defaultContentsJsonString.
	self assert: (parsed at: 'port') equals: 0.
	self assert: (parsed at: 'no_open').
	self assert: (parsed at: 'ignore_patterns') equals: #( '.crit.config.json' )
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortAssigns9080Then9081 [

	| firstDir secondDir first second |
	AbSettings default useCrit: true.
	firstDir := self directoryNamed: 'first'.
	secondDir := self directoryNamed: 'second'.
	first := self topicAt: firstDir.
	second := self topicAt: secondDir.
	self assert: (AbCritConfigFile assignPortIn: first workingDirectory amongTopics: { first }) equals: 9080.
	self assert: (AbCritConfigFile in: firstDir) port equals: 9080.
	self assert: (AbCritConfigFile assignPortIn: second workingDirectory amongTopics: { first. second }) equals: 9081.
	self assert: (AbCritConfigFile in: secondDir) port equals: 9081
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortSkipsHandWrittenAndUnreadablePorts [

	| taken broken fresh takenTopic brokenTopic freshTopic |
	AbSettings default useCrit: true.
	taken := self directoryNamed: 'taken'.
	broken := self directoryNamed: 'broken'.
	fresh := self directoryNamed: 'fresh'.
	self writeJson: (Dictionary new at: 'port' put: 9080; yourself) in: taken.
	(broken / '.crit.config.json') writeStreamDo: [ :stream | stream nextPutAll: '{' ].
	takenTopic := self topicAt: taken.
	brokenTopic := self topicAt: broken.
	freshTopic := self topicAt: fresh.
	self assert: (AbCritConfigFile
		assignPortIn: freshTopic workingDirectory
		amongTopics: { takenTopic. brokenTopic. freshTopic }) equals: 9081
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortIgnoresTheTargetDirectory [

	| dir topic |
	AbSettings default useCrit: true.
	dir := self directoryNamed: 'target'.
	self writeJson: (Dictionary new at: 'port' put: 9080; yourself) in: dir.
	topic := self topicAt: dir.
	self assert: (AbCritConfigFile assignPortIn: topic workingDirectory amongTopics: { topic }) equals: 9080
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortDoesNothingWhenUseCritIsFalse [

	| dir topic parsed |
	dir := self directoryNamed: 'off'.
	self writeJson: (Dictionary new at: 'port' put: 0; at: 'no_open' put: true; yourself) in: dir.
	topic := self topicAt: dir.
	self assert: (AbCritConfigFile assignPortIn: topic workingDirectory amongTopics: { topic }) isNil.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 0
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortDoesNothingWhenRangeIsInvalid [

	| dir topic parsed |
	AbSettings default useCrit: true.
	AbSettings default critPortRange: '9080-'.
	dir := self directoryNamed: 'bad-range'.
	self writeJson: (Dictionary new at: 'port' put: 0; yourself) in: dir.
	topic := self topicAt: dir.
	self assert: (AbCritConfigFile assignPortIn: topic workingDirectory amongTopics: { topic }) isNil.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 0
]

{ #category : 'tests' }
AbCritConfigFileTest >> testAssignPortExhaustedWritesNothingAndWarns [

	| held dir heldTopic topic warnings logger parsed |
	AbSettings default useCrit: true.
	AbSettings default critPortRange: '9080-9080'.
	held := self directoryNamed: 'held'.
	dir := self directoryNamed: 'full'.
	self writeJson: (Dictionary new at: 'port' put: 9080; yourself) in: held.
	self writeJson: (Dictionary new at: 'port' put: 0; at: 'extra' put: 'stay'; yourself) in: dir.
	heldTopic := self topicAt: held.
	topic := self topicAt: dir.
	warnings := OrderedCollection new.
	logger := MockObject new.
	logger on: #warn: withArguments: nil verify: [ :record | warnings add: record ].
	topic instVarNamed: 'logger' put: logger.
	self assert: (AbCritConfigFile assignPortIn: topic workingDirectory amongTopics: { heldTopic. topic }) isNil.
	parsed := STONJSON fromString: (dir / '.crit.config.json') contents.
	self assert: (parsed at: 'port') equals: 0.
	self assert: (parsed at: 'extra') equals: 'stay'.
	self assert: warnings size equals: 1.
	self assert: (warnings first asString includesSubstring: 'crit port range exhausted')
]
