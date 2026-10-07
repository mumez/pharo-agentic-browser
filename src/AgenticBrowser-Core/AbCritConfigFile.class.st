"
I am the .crit.config.json of one working directory.

Responsibility:
- I read and write the port, leaving every other key intact.
- I treat a missing file, unreadable JSON, 0, or a port outside 1..65535 as unassigned.
- I own the built-in default document used when a directory has no readable config.
- On the class side I assign the lowest free port in AbSettings default critPortInterval to a newly created working directory.

Collaborators:
- AbSettings: I read #useCrit and #critPortInterval before assigning a port.
- AbWorkingDirectory: #ensureExists asks me to assign a port after the template copy.
- AbTopicManager: my class-side topicManager supplies the topics whose ports are already in use.
- AbTopic: I read each topic's working directory when collecting ports already in use, and I warn through the target topic's logger when the range is exhausted.

Public API and Key Messages:
- AbCritConfigFile class>>in: - Config file for one directory.
- AbCritConfigFile class>>assignPortIn: - Assign the lowest free port among the topicManager's topics, or nil when assignment does not happen.
- AbCritConfigFile class>>assignPortIn:amongTopics: - Same, among the given topics.
- AbCritConfigFile class>>topicManager: - Inject the AbTopicManager to consult (defaults to AbTopicManager default).
- #port - Assigned port, or nil. Cached once read, since an assigned port does not change.
- #writePort: - Set port in the existing document, or in the built-in default when the file is missing or unreadable.

Internal Representation:
- directory - FileReference of the working directory that contains .crit.config.json.
- port - Cached assigned port; nil until a valid port is read or written.
- PortAssignmentMutex (class) - Serializes read-pick-write port assignment.
- topicManager (class inst var) - AbTopicManager whose topics are scanned for used ports; nil means AbTopicManager default.
"
Class {
	#name : 'AbCritConfigFile',
	#superclass : 'Object',
	#instVars : [
		'directory',
		'port'
	],
	#classVars : [
		'PortAssignmentMutex'
	],
	#classInstVars : [
		'topicManager'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbCritConfigFile class >> in: aDirectoryReference [

	^ self new
		  directory: aDirectoryReference;
		  yourself
]

{ #category : 'accessing' }
AbCritConfigFile class >> fileName [

	^ '.crit.config.json'
]

{ #category : 'defaults' }
AbCritConfigFile class >> defaultContents [

	^ Dictionary new
		  at: 'port' put: 0;
		  at: 'no_open' put: true;
		  at: 'ignore_patterns' put: #( '.crit.config.json' );
		  yourself
]

{ #category : 'accessing' }
AbCritConfigFile class >> topicManager [

	^ topicManager ifNil: [ AbTopicManager default ]
]

{ #category : 'accessing' }
AbCritConfigFile class >> topicManager: anAbTopicManager [

	topicManager := anAbTopicManager
]

{ #category : 'port assignment' }
AbCritConfigFile class >> assignPortIn: anAbWorkingDirectory [

	^ self
		  assignPortIn: anAbWorkingDirectory
		  amongTopics: self topicManager topics
]

{ #category : 'port assignment' }
AbCritConfigFile class >> assignPortIn: anAbWorkingDirectory amongTopics: aTopicCollection [

	^ self portAssignmentMutex critical: [
		  self
			  basicAssignPortIn: anAbWorkingDirectory
			  amongTopics: aTopicCollection ]
]

{ #category : 'private' }
AbCritConfigFile class >> basicAssignPortIn: anAbWorkingDirectory amongTopics: aTopicCollection [

	| interval used port |
	AbSettings default useCrit ifFalse: [ ^ nil ].
	interval := AbSettings default critPortInterval ifNil: [ ^ nil ].
	used := self usedPortsAmong: aTopicCollection excluding: anAbWorkingDirectory path.
	port := interval
		        detect: [ :each | (used includes: each) not ]
		        ifNone: [
			        anAbWorkingDirectory topic logger warn: {
					        self name.
					        #assignPortIn:amongTopics:.
					        'crit port range exhausted'.
					        interval }.
			        ^ nil ].
	(self in: anAbWorkingDirectory path) writePort: port.
	^ port
]

{ #category : 'private' }
AbCritConfigFile class >> portAssignmentMutex [

	^ PortAssignmentMutex ifNil: [ PortAssignmentMutex := Mutex new ]
]

{ #category : 'private' }
AbCritConfigFile class >> usedPortsAmong: aTopicCollection excluding: aDirectoryReference [

	| excluded |
	excluded := aDirectoryReference fullName.
	^ aTopicCollection inject: Set new into: [ :used :topic |
		  | dir |
		  dir := topic workingDirectory path.
		  dir fullName = excluded ifFalse: [
			  (self in: dir) port ifNotNil: [ :port | used add: port ] ].
		  used ]
]

{ #category : 'accessing' }
AbCritConfigFile >> directory [

	^ directory
]

{ #category : 'accessing' }
AbCritConfigFile >> directory: aDirectoryReference [

	directory := aDirectoryReference
]

{ #category : 'accessing' }
AbCritConfigFile >> file [

	^ self directory / self class fileName
]

{ #category : 'accessing' }
AbCritConfigFile >> port [

	^ port ifNil: [ port := self readPort ]
]

{ #category : 'private' }
AbCritConfigFile >> readPort [

	| raw |
	raw := [ (STONJSON fromString: self file contents) at: 'port' ifAbsent: [ nil ] ]
		       on: Error
		       do: [ nil ].
	(raw isInteger and: [ raw between: 1 and: 65535 ]) ifFalse: [ ^ nil ].
	^ raw
]

{ #category : 'operations' }
AbCritConfigFile >> writePort: anInteger [

	| contents |
	contents := self contentsOrDefault.
	contents at: 'port' put: anInteger.
	self file writeStreamDo: [ :stream |
		stream nextPutAll: (STONJSON toStringPretty: contents) ].
	port := anInteger
]

{ #category : 'private' }
AbCritConfigFile >> contentsOrDefault [

	^ [ STONJSON fromString: self file contents ]
		  on: Error
		  do: [ self class defaultContents ]
]
