"
I am the singleton registry and persistence manager for all AbTopic instances.

Responsibility:
- I maintain the collection of active topics keyed by their topicId.
- I persist topics to and load them from a Fuel binary file (ab-topics.fuel).
- I announce AbTopicAdded when a topic is registered.
- I announce AbTopicRemoved when a topic is removed.
- I clean up (stop watching, disconnect) topics on removal or image re-initialization.
- I provide topic lookup by topicId, working directory path, and name.
- I drop stale ACP client connections for all topics when the image resumes after a save/restart.
- I persist myself automatically whenever the image saves or quits, so topics survive a Pharo exit even if the AgenticBrowser window was never closed.
- I run a background process that periodically scans all topics for stalled ones and nudges them with a resume prompt.
- I start watching for related-package changes across all my topics automatically. Both watching and stall monitoring start as soon as I am accessed (via #default or #load), independent of any UI (Pharo window, Web UI, or orchestration scripts) — watching a topic's packages is harmless even in a headless environment where no human edits will ever happen.

Collaborators:
- AbTopic: I own and lifecycle-manage all topic instances.
- AbTopicAdded: I announce it when a new topic is added.
- AbTopicRemoved: I announce it when a topic is removed.
- FLSerializer / FLMaterializer: I use the Fuel framework for binary serialization.

Public API and Key Messages:
- AbTopicManager class>>#default - Access the global singleton.
- AbTopicManager class>>load / #save - Load from / save to ab-topics.fuel.
- #addTopic: - Register a topic and announce AbTopicAdded.
- #removeTopic: - Teardown, deregister, and announce AbTopicRemoved.
- #topics - All registered topics as an Array.
- #topicNamed: - Look up the first topic by name (lexicographic topicId order).
- #topicForWorkingDirectoryPath: - Look up a topic by its working directory path.
- #startStalledTopicsMonitoring / #stopStalledTopicsMonitoring - Start or stop the background stall-monitoring process.
- #resumeStalledTopics - Send each stalled topic's goal resume prompt once, synchronously.

Internal Representation:
- topics - Dictionary keyed by topicId String, valued by AbTopic.
- announcer - Lazy Announcer; excluded from Fuel and recreated lazily after load.
- stallMonitoringProcess - Background Process that periodically calls #resumeStalledTopics; excluded from Fuel.
- default (class inst var) - The global singleton instance.
- forTest (class inst var) - Isolated instance used by the test suite; does not affect the global instance.

Implementation Points:
- announcer is excluded from Fuel serialization; subscribers must re-subscribe after each load.
- #cleanupAllTopics stops watchers and disconnects agents; called before replacing the default instance on load, and on actual image quit (not a plain save) via class>>shutDown:.
- class>>initialize registers this class on Smalltalk's start-up and shut-down lists; class>>startUp: calls #resetStaleConnections on the default instance when the image resumes, so topics left open across a save/restart reconnect instead of writing to a dead subprocess's pipes.
- class>>shutDown: calls #save only when a default instance already exists in memory, to avoid lazily creating and persisting an empty manager when AgenticBrowser was never opened this session. It only tears down watchers/connections/monitoring when isImageQuitting is true; a plain image save (isImageQuitting false) leaves them running since the image keeps executing afterward.
- The monitoring loop sleeps for AbSettings>>#stallMonitoringIntervalSeconds between scans and swallows per-topic errors so one failing #sendPrompt: does not stop the rest from being checked.
- class>>default starts watching and monitoring the instant the singleton is lazily created; class>>defaultLoaded: (used by class>>load) starts both on the freshly loaded instance too, so any entry point that touches the default manager (Pharo UI, Web UI, orchestration scripts) gets them for free.
"
Class {
	#name : 'AbTopicManager',
	#superclass : 'Object',
	#instVars : [
		'topics',
		'announcer',
		'stallMonitoringProcess'
	],
	#classInstVars : [
		'default',
		'forTest',
		'announcer'
	],
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'instance creation' }
AbTopicManager class >> default [

	default ifNil: [
		default := self new.
		default startAllTopicsWatching.
		default startStalledTopicsMonitoring ].
	^ default
]

{ #category : 'accessing-default' }
AbTopicManager class >> default: anInstance [

	default := anInstance
]

{ #category : 'accessing-default' }
AbTopicManager class >> defaultLoaded: anInstance [
	"Set anInstance as the default and announce AbTopicManagerLoaded so subscribers
	(e.g. AbTopicListPresenter) refresh against it. Use this instead of #default: whenever
	a UI may already be observing the previous default, such as restoring the original
	manager after a test swaps it out."

	default ifNotNil: [
		default cleanupAllTopics.
		default stopStalledTopicsMonitoring ].
	self default: anInstance.
	anInstance ifNil: [ ^ self ].
	anInstance startAllTopicsWatching.
	anInstance startStalledTopicsMonitoring.
	self announcer announce: (AbTopicManagerLoaded topicManager: anInstance)
]

{ #category : 'announcements' }
AbTopicManager class >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'persistence' }
AbTopicManager class >> defaultFileReference [

	^ AbSettings defaultAgenticBrowserRootDirectory / self fileName
]

{ #category : 'persistence' }
AbTopicManager class >> fileName [

	^ 'ab-topics.fuel'
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest [

	^ forTest ifNil: [ forTest := self new ]
]

{ #category : 'instance creation' }
AbTopicManager class >> forTest: anInstance [

	forTest := anInstance
]

{ #category : 'fuel' }
AbTopicManager class >> fuelIgnoredInstanceVariableNames [

	^ #( 'announcer' 'stallMonitoringProcess' )
]

{ #category : 'class initialization' }
AbTopicManager class >> initialize [

	default ifNotNil: [
		default cleanupAllTopics.
		default stopStalledTopicsMonitoring ].
	default := forTest := nil.
	Smalltalk addToStartUpList: self.
	Smalltalk addToShutDownList: self
]

{ #category : 'system startup' }
AbTopicManager class >> startUp: resuming [
	"Called by the session manager when the image resumes. If topics were left open across
	a Pharo image save/restart (not a Fuel reload), their ACP client still references the
	previous session's dead subprocess and pipes; drop those stale references so the next
	prompt reconnects and resumes the ACP session instead of writing to a closed pipe."

	resuming ifFalse: [ ^ self ].
	default ifNotNil: [
		default resetStaleConnections.
		default startAllTopicsWatching.
		default startStalledTopicsMonitoring ]
]

{ #category : 'system startup' }
AbTopicManager class >> shutDown: isImageQuitting [
	"Called by the session manager whenever the image saves or quits, including when Pharo
	is closed without the AgenticBrowser window ever being closed. Only save if a default
	instance already exists in memory; otherwise this would lazily create an empty manager
	and overwrite whatever was previously persisted. The save is guarded so a serialization
	failure cannot abort the image save/quit. Watchers, agent connections, and stall
	monitoring are only torn down when the image is actually quitting (not on a plain save),
	since they should otherwise keep running regardless of whether any UI window is open."

	default ifNotNil: [ :defaultInstance |
		isImageQuitting ifTrue: [
			defaultInstance cleanupAllTopics.
			defaultInstance stopStalledTopicsMonitoring ].
		[ defaultInstance save ]
			on: Error
			do: [ :e | "ignore; do not abort the image save/quit" ] ]
]

{ #category : 'persistence' }
AbTopicManager class >> load [

	| newDefault |
	self defaultFileReference exists ifFalse: [ ^ self ].
	default ifNotNil: [
		default cleanupAllTopics.
		default stopStalledTopicsMonitoring ].
	newDefault := self loadFrom: self defaultFileReference.
	self defaultLoaded: newDefault
]

{ #category : 'persistence' }
AbTopicManager class >> loadFrom: aFileReference [

	^ FLMaterializer materializeFromFileNamed: aFileReference fullName
]

{ #category : 'persistence' }
AbTopicManager class >> save [

	self default save
]

{ #category : 'persistence' }
AbTopicManager class >> saveTo: aFileReference [

	self default saveTo: aFileReference
]

{ #category : 'persistence' }
AbTopicManager >> save [

	self saveTo: self class defaultFileReference
]

{ #category : 'persistence' }
AbTopicManager >> saveTo: aFileReference [

	aFileReference parent ensureCreateDirectory.
	FLSerializer serialize: self toFileNamed: aFileReference fullName
]

{ #category : 'operations' }
AbTopicManager >> addTopic: anAbTopic [

	topics at: anAbTopic topicId put: anAbTopic.
	self announcer announce: (AbTopicAdded topic: anAbTopic)
]

{ #category : 'accessing' }
AbTopicManager >> announcer [

	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'accessing' }
AbTopicManager >> at: aTopicId [

	^ topics at: aTopicId ifAbsent: [ nil ]
]

{ #category : 'operations' }
AbTopicManager >> cleanupAllTopics [

	topics valuesDo: [ :topic | self teardownTopic: topic ]
]

{ #category : 'operations' }
AbTopicManager >> resetStaleConnections [
	"Drop each topic's ACP client without touching its watchers, so topics left open
	across an image restart reconnect fresh on the next prompt. Unlike #cleanupAllTopics,
	this does not stop related-packages watching, since the topics are still in active use."

	topics valuesDo: [ :topic |
		[ topic disconnect ]
			on: Error
			do: [ :e | topic logger warn: 'resetStaleConnections: disconnect failed - ' , e messageText ] ]
]

{ #category : 'initialization' }
AbTopicManager >> initialize [

	topics := Dictionary new
]

{ #category : 'operations' }
AbTopicManager >> removeTopic: anAbTopic [

	| removedTopic |
	self teardownTopic: anAbTopic.
	removedTopic := topics removeKey: anAbTopic topicId ifAbsent: [ ^ self ].
	self announcer announce: (AbTopicRemoved topic: removedTopic)
]

{ #category : 'operations' }
AbTopicManager >> startAllTopicsWatching [

	topics valuesDo: [ :t | t startWatching ]
]

{ #category : 'private' }
AbTopicManager >> teardownTopic: aTopic [

	aTopic stopWatching.
	[ aTopic disconnect ]
		on: Error
		do: [ :e | aTopic logger warn: 'teardownTopic: disconnect failed - ' , e messageText ]
]

{ #category : 'accessing' }
AbTopicManager >> topicForWorkingDirectoryPath: aString [

	| lookupPath |
	lookupPath := aString asFileReference fullName.
	^ topics values
		detect: [ :each |
			each workingDirectoryPath asFileReference fullName = lookupPath ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
AbTopicManager >> topicNamed: aString [

	| matches |
	matches := self topicsNamed: aString.
	matches ifEmpty: [ ^ nil ].
	^ (matches asSortedCollection: [ :a :b | a topicId < b topicId ]) first
]

{ #category : 'accessing' }
AbTopicManager >> topics [
	^ topics values asArray
]

{ #category : 'accessing' }
AbTopicManager >> topicsNamed: aString [

	^ topics values select: [ :each | each name = aString ]
]

{ #category : 'operations' }
AbTopicManager >> topicsDo: aBlock [

	topics valuesDo: aBlock
]

{ #category : 'operations' }
AbTopicManager >> stopAllTopicsWatching [

	topics valuesDo: [ :t | t stopWatching ]
]

{ #category : 'testing' }
AbTopicManager >> isMonitoringStalledTopics [

	^ stallMonitoringProcess notNil and: [ stallMonitoringProcess isTerminated not ]
]

{ #category : 'operations' }
AbTopicManager >> resumeStalledTopics [

	(self topics select: [ :t | t isStalled ]) do: [ :t |
		[ t sendPrompt: t topicGoal resumePrompt ]
			on: Error
			do: [ :e | t logger warn: 'resumeStalledTopics: sendPrompt: failed - ' , e messageText ] ]
]

{ #category : 'private' }
AbTopicManager >> runStallMonitoringLoop [

	[ stallMonitoringProcess notNil ] whileTrue: [
		(Delay forSeconds: AbSettings default stallMonitoringIntervalSeconds) wait.
		self resumeStalledTopics ]
]

{ #category : 'monitoring' }
AbTopicManager >> startStalledTopicsMonitoring [

	self isMonitoringStalledTopics ifTrue: [ ^ self ].
	stallMonitoringProcess := [ self runStallMonitoringLoop ] newProcess
		name: 'AgenticBrowser topics stall monitor';
		priority: Processor userBackgroundPriority;
		yourself.
	stallMonitoringProcess resume
]

{ #category : 'monitoring' }
AbTopicManager >> stopStalledTopicsMonitoring [

	stallMonitoringProcess ifNotNil: [ :p | p terminate ].
	stallMonitoringProcess := nil
]
