Class {
	#name : 'AbCritReviewFinishResultsManagerTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Crit-Tests',
	#package : 'AgenticBrowser-Crit-Tests'
}

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testDefaultIsSingleton [

	self assert: AbCritReviewFinishResultsManager default identicalTo: AbCritReviewFinishResultsManager default
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testDirectoryIsUnderAgenticBrowserRoot [

	self
		assert: AbCritReviewFinishResultsManager new directory
		equals: AbSettings defaultAgenticBrowserRootDirectory / '_crit-results'
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testFileForTopicIdKindNamesTopicAndKind [

	| manager |
	manager := AbCritReviewFinishResultsManager new.
	self
		assert: (manager fileForTopicId: 'abc' kind: #unresolved)
		equals: manager directory / 'abc-unresolved.json'.
	self
		assert: (manager fileForTopicId: 'abc' kind: #approved)
		equals: manager directory / 'abc-approved.json'
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testFilesForTopicIdCoverEveryKind [

	| manager |
	manager := AbCritReviewFinishResultsManager new.
	self
		assert: (manager filesForTopicId: 'abc') asArray
		equals: {
				(manager fileForTopicId: 'abc' kind: #unresolved).
				(manager fileForTopicId: 'abc' kind: #approved) }
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testIsSystemDefinedHookCommandRecognizesCommandsWritingIntoResultDirectory [

	| manager |
	manager := AbCritReviewFinishResultsManager new.
	self assert: (manager isSystemDefinedHookCommand: 'inline:cat > ''/old/root/agentic-browser/_crit-results/abc-unresolved.json''').
	self assert: (manager isSystemDefinedHookCommand: 'inline:cat > ' , '/r/it''s/_crit-results/a-b-approved.json' shellQuoted).
	self deny: (manager isSystemDefinedHookCommand: 'inline:echo done >> ~/finishes.log').
	self deny: (manager isSystemDefinedHookCommand: 'inline:cat > ~/_crit-results/out.json').
	self deny: (manager isSystemDefinedHookCommand: 'inline:cat > ''/home/u/_crit-results/out.json''').
	self deny: (manager isSystemDefinedHookCommand: 'inline:cat > ''/x/_crit-results/a-unresolved.json'' && notify').
	self deny: (manager isSystemDefinedHookCommand: nil)
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testIsSystemDefinedHookCommandRecognizesCommandsWritingIntoLegacyResultDirectory [

	| manager |
	manager := AbCritReviewFinishResultsManager new.
	self assert: (manager isSystemDefinedHookCommand: 'inline:cat > ''/old/root/agentic-browser/crit-results/abc-unresolved.json''').
	self assert: (manager isSystemDefinedHookCommand: 'inline:cat > ' , '/r/it''s/crit-results/a-b-approved.json' shellQuoted).
	self deny: (manager isSystemDefinedHookCommand: 'inline:cat > ''/old/other-results/abc-unresolved.json''')
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testResultsReadTopicIdAndKindFromResultFilesOnly [

	| dir results |
	dir := FileSystem memory root / 'crit-results'.
	dir ensureCreateDirectory.
	#( 'a1-b2-unresolved.json' 't2-approved.json' 'notes.txt' 't3-other.json' 't4-unresolved.json.tmp' ) do: [ :name |
		(dir / name) writeStreamDo: [ :stream | stream nextPutAll: '{}' ] ].
	results := (AbCritReviewFinishResultsManager new directory: dir; yourself) results.
	self
		assert: (results collect: [ :each | each topicId -> each kind ]) asSet
		equals: { ('a1-b2' -> #unresolved). ('t2' -> #approved) } asSet.
	self assert: (results detect: [ :each | each topicId = 't2' ]) file equals: dir / 't2-approved.json'
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testResultsOfMissingDirectoryAreEmpty [

	| manager |
	manager := AbCritReviewFinishResultsManager new directory: FileSystem memory root / 'missing'; yourself.
	self assert: manager results isEmpty
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testPrepareFinishHooksForSavesPayloadIntoTopicFiles [

	| manager topic hooks |
	manager := AbCritReviewFinishResultsManager new directory: FileSystem memory root / 'it''s'; yourself.
	topic := AbTopic new.
	hooks := manager prepareFinishHooksFor: topic.
	self assert: hooks keys asSet equals: #( 'on_finish_unresolved' 'on_finish_approved' ) asSet.
	manager finishKinds do: [ :kind |
		self
			assert: (hooks at: 'on_finish_' , kind)
			equals: 'inline:cat > ' , (manager fileForTopicId: topic topicId kind: kind) fullName shellQuoted ].
	self assert: ((hooks at: 'on_finish_approved') includesSubstring: '''\''')
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testDeleteFilesForDeletesOnlyThatTopicsFiles [

	| manager topic otherFile |
	manager := AbCritReviewFinishResultsManager new directory: FileSystem memory root / 'crit-results'; yourself.
	manager directory ensureCreateDirectory.
	topic := AbTopic new.
	(manager filesForTopicId: topic topicId) do: [ :file | file ensureCreateFile ].
	otherFile := (manager fileForTopicId: 'other' kind: #unresolved) ensureCreateFile; yourself.
	manager deleteFilesFor: topic.
	self deny: ((manager filesForTopicId: topic topicId) anySatisfy: [ :file | file exists ]).
	self assert: otherFile exists
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testFinishHooksAttachedToForAddsThemKeepingOtherHooks [

	| manager topic original hooks |
	manager := AbCritReviewFinishResultsManager new directory: FileSystem memory root / 'crit-results'; yourself.
	topic := AbTopic new.
	original := Dictionary new
		at: 'on_review_start' put: 'inline:true';
		at: 'on_finish_unresolved' put: 'inline:cat > ''/old/crit-results/x-unresolved.json''';
		yourself.
	hooks := manager finishHooksAttachedTo: original for: topic.
	self assert: (hooks at: 'on_review_start') equals: 'inline:true'.
	(manager prepareFinishHooksFor: topic) keysAndValuesDo: [ :name :command |
		self assert: (hooks at: name) equals: command ].
	self assert: (original at: 'on_finish_unresolved') equals: 'inline:cat > ''/old/crit-results/x-unresolved.json'''
]

{ #category : 'tests' }
AbCritReviewFinishResultsManagerTest >> testFinishHooksAttachedToForIsNilWhenUserDefinedFinishHookExists [

	| manager original |
	manager := AbCritReviewFinishResultsManager new directory: FileSystem memory root / 'crit-results'; yourself.
	original := Dictionary new at: 'on_finish_approved' put: 'inline:echo approved >> ~/finishes.log'; yourself.
	self assert: (manager finishHooksAttachedTo: original for: AbTopic new) isNil
]
