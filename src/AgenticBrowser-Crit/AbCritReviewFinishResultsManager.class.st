"
I am the singleton that owns the result files of crit review Finishes, written as JSON files by the finish hooks that AgenticBrowser puts in .crit.config.json.

Responsibility:
- I own where result files live and how they are named: one file per topic and finish kind (unresolved or approved) under crit-results/ in the AgenticBrowser root directory.
- I prepare a topic's finish hooks, which save crit's finish payload into my files, and merge them into given hooks unless the user defined a finish hook there.
- I delete a topic's result files.
- I recognize finish hook commands that write into my directory, so a hook from an earlier AgenticBrowser root is still treated as ours.
- I list the result files in my directory as AbCritReviewFinishResult instances, reading the topicId and kind from each file name.
- I deliver each pending result to its topic while the topic's crit daemon awaits its first finish: an approval becomes a system message, and an unresolved result becomes a prompt once the topic is #endTurn or #initial. After delivering, I announce AbCritReviewFinished on the topic's announcer. Results of unknown topics and later rounds are deleted without an announcement. A result that cannot be read (for example while crit's hook is still writing it) is logged and kept for the next delivery.

Collaborators:
- AbSettings: I read #defaultAgenticBrowserRootDirectory, and #useCrit through #settings.
- AbCritReviewFinishResult: I create one per result file.
- AbCritDaemon: It asks me to delete its topic's stale files when a review starts.
- AbCritConfigFile: It passes me its hooks to attach a topic's finish hooks to, and writes back the ones I answer.
- AbTopicManager: It asks me to deliver pending results to its topics, which I look up with its #at:.
- AbTopic: I send it the prompt or system message, read its status, logger, and crit daemon, and announce on its announcer.
- AbCritReviewFinished: I announce one per delivered result.
- AbCritDaemon: I ask whether it awaits its first finish, and clear that once delivered.

Public API and Key Messages:
- #finishHooksAttachedTo:for: - Create my directory and answer a copy of the given hooks with a topic's finish hooks set; nil when one of those hook names already holds a user-defined command.
- #deleteFilesFor: - Delete a topic's result files.
- #deliverResultsToTopicsIn: - Deliver the pending results to the topics of an AbTopicManager, as described above. Does nothing while useCrit is false.

Internal Representation:
- directory - Overrides the crit-results directory (tests use an in-memory one); nil means under the AgenticBrowser root directory.
- default (class inst var) - The global singleton instance.
"
Class {
	#name : 'AbCritReviewFinishResultsManager',
	#superclass : 'Object',
	#instVars : [
		'directory'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AgenticBrowser-Crit',
	#package : 'AgenticBrowser-Crit'
}

{ #category : 'class initialization' }
AbCritReviewFinishResultsManager class >> initialize [

	default := nil
]

{ #category : 'instance creation' }
AbCritReviewFinishResultsManager class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> directoryName [

	^ 'crit-results'
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> directory [

	^ directory ifNil: [ AbSettings defaultAgenticBrowserRootDirectory / self directoryName ]
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> directory: aDirectoryReference [

	directory := aDirectoryReference
]

{ #category : 'constants' }
AbCritReviewFinishResultsManager >> finishKinds [

	^ self class finishKinds
]

{ #category : 'constants' }
AbCritReviewFinishResultsManager class >> finishKinds [

	^ #( #unresolved #approved )
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> fileNameSuffixFor: aKindSymbol [

	^ '-' , aKindSymbol , '.json'
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> fileForTopicId: aTopicIdString kind: aKindSymbol [

	^ self directory / (aTopicIdString , (self fileNameSuffixFor: aKindSymbol))
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> filesForTopicId: aTopicIdString [

	^ self finishKinds collect: [ :kind | self fileForTopicId: aTopicIdString kind: kind ]
]

{ #category : 'preparing-hooks' }
AbCritReviewFinishResultsManager >> prepareFinishHooksFor: aTopic [

	^ self finishKinds
		  inject: Dictionary new
		  into: [ :hooks :kind |
			  hooks
				  at: 'on_finish_' , kind
				  put: 'inline:cat > ' , (self fileForTopicId: aTopic topicId kind: kind) fullName shellQuoted;
				  yourself ]
]

{ #category : 'preparing-hooks' }
AbCritReviewFinishResultsManager >> finishHooksAttachedTo: aHookDictionary for: aTopic  [

	| finishHooks |
	self directory ensureCreateDirectory.
	finishHooks := self prepareFinishHooksFor: aTopic.
	(self hasUserDefinedHookNamedAnyOf: finishHooks keys in: aHookDictionary) ifTrue: [ ^ nil ].
	^ aHookDictionary copy
		  addAll: finishHooks;
		  yourself
]

{ #category : 'private' }
AbCritReviewFinishResultsManager >> hasUserDefinedHookNamedAnyOf: aHookNameCollection in: aHookDictionary [

	^ aHookNameCollection anySatisfy: [ :name |
		  (aHookDictionary at: name ifAbsent: [ nil ])
			  ifNil: [ false ]
			  ifNotNil: [ :command | (self isSystemDefinedHookCommand: command) not ] ]
]

{ #category : 'operations' }
AbCritReviewFinishResultsManager >> deleteFilesFor: aTopic [

	(self filesForTopicId: aTopic topicId) do: [ :file | file ensureDelete ]
]

{ #category : 'testing' }
AbCritReviewFinishResultsManager >> isSystemDefinedHookCommand: aCommandString [

	^ aCommandString isString and: [
		  aCommandString matchesRegex: 'inline\:cat > ''.*/' , self directoryName , '/[^/]+-(' , ('|' join: self finishKinds) , ')\.json''' ]
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> results [

	self directory exists ifFalse: [ ^ #(  ) ].
	^ self finishKinds flatCollect: [ :kind |
		  | suffix |
		  suffix := self fileNameSuffixFor: kind.
		  (self directory files select: [ :file | file basename endsWith: suffix ]) collect: [ :file |
			  AbCritReviewFinishResult
				  file: file
				  topicId: (file basename allButLast: suffix size)
				  kind: kind ] ]
]

{ #category : 'accessing' }
AbCritReviewFinishResultsManager >> settings [

	^ AbSettings default
]

{ #category : 'operations' }
AbCritReviewFinishResultsManager >> deliverResultsToTopicsIn: anAbTopicManager [

	self settings useCrit ifFalse: [ ^ self ].
	self results do: [ :result |
		| topic |
		topic := anAbTopicManager at: result topicId.
		[ self deliverResult: result toTopic: topic ]
			on: Error
			do: [ :e | self logRetryOfResult: result toTopic: topic failure: e ] ]
]

{ #category : 'private' }
AbCritReviewFinishResultsManager >> deliverResult: anAbCritReviewFinishResult toTopic: aTopicOrNil [

	| daemon finished |
	aTopicOrNil ifNil: [
		Transcript crShow: 'AbCritReviewFinishResultsManager: discarding crit result of unknown topic ' , anAbCritReviewFinishResult topicId.
		^ anAbCritReviewFinishResult delete ].
	daemon := aTopicOrNil critDaemon.
	daemon isAwaitingFirstFinish ifFalse: [
		aTopicOrNil logger info: 'deliverResultsToTopicsIn: discarding a later crit result'.
		^ anAbCritReviewFinishResult delete ].
	anAbCritReviewFinishResult isApproved
		ifTrue: [ aTopicOrNil addSystemMessage: 'Crit review approved.' ]
		ifFalse: [
			(aTopicOrNil isEndTurn or: [ aTopicOrNil isInitial ]) ifFalse: [ ^ self ].
			aTopicOrNil sendPrompt: anAbCritReviewFinishResult prompt ].
	finished := self finishAnnouncementOf: anAbCritReviewFinishResult toTopic: aTopicOrNil.
	anAbCritReviewFinishResult delete.
	daemon awaitingFirstFinish: false.
	aTopicOrNil announcer announce: finished
]

{ #category : 'private' }
AbCritReviewFinishResultsManager >> finishAnnouncementOf: anAbCritReviewFinishResult toTopic: aTopic [
	"Build this before the result file is deleted, because it reads the result's payload."

	^ AbCritReviewFinished
		  topic: aTopic
		  kind: anAbCritReviewFinishResult kind
		  unresolvedCount: anAbCritReviewFinishResult unresolvedCount
]

{ #category : 'private' }
AbCritReviewFinishResultsManager >> logRetryOfResult: anAbCritReviewFinishResult toTopic: aTopicOrNil failure: anError [

	| text |
	text := 'deliverResultsToTopicsIn: will retry ' , anAbCritReviewFinishResult file basename , ' - ' , anError messageText.
	aTopicOrNil
		ifNil: [ Transcript crShow: 'AbCritReviewFinishResultsManager: ' , text ]
		ifNotNil: [ aTopicOrNil logger warn: text ]
]
