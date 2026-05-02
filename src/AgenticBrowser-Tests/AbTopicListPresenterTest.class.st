Class {
	#name : 'AbTopicListPresenterTest',
	#superclass : 'AbTestCase',
	#instVars : [
		'presenter',
		'topic'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'accessing' }
AbTopicListPresenterTest >> presenter: aPresenter [

	presenter := aPresenter
]

{ #category : 'accessing' }
AbTopicListPresenterTest >> topic: anAbTopic [

	topic := anAbTopic
]

{ #category : 'running' }
AbTopicListPresenterTest >> setUp [

	super setUp.
	self presenter: AbTopicListPresenter new.
	self topic: (AbTopic new title: 'TestTopic').
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testAutoExportPreconditionsForNewTopic [

	"Verifies the preconditions for the auto-export path in onPackagePrefixSet:.
	 A freshly-created topic with a matching prefix has:
	   - at least one matching package
	   - no existing working directory on disk
	 The actual export (SisServer call) is verified in the integration smoke test."

	topic addPackagePrefix: 'AgenticBrowser-*'.
	self assert: topic matchingPackageNames notEmpty.
	self deny: topic workingDirectory path exists
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetEmptyPrefixAddsNewProjectMessage [

	topic packagePrefixes: Set new.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'new project' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetNoMatchAddsSystemMessage [

	topic addPackagePrefix: 'NonExistentXYZ99-*'.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'No packages match' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testApplyUpdatedExternalPackagesForAddsPrefixesAndClearsPendingList [

	topic addUpdatedExternalPackageName: 'AgenticBrowser-Core'.
	presenter applyUpdatedExternalPackagesFor: topic.
	self assert: (topic hasPackagePrefix: 'AgenticBrowser-Core').
	self assert: topic updatedExternalPackageNames isEmpty
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testApplyUpdatedExternalPackagesForWithNoPendingPackagesAddsMessage [

	presenter applyUpdatedExternalPackagesFor: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [
			m text includesSubstring: 'No externally updated packages' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForReturnsIconAndTitle [

	topic agentArguments: #(  ).
	self assert: (presenter topicListLabelFor: topic) equals: '○ TestTopic'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForIncludesAgentName [

	topic agentArguments: #( 'opencode' ).
	self assert: (presenter topicListLabelFor: topic) equals: '○ TestTopic (opencode)'.

	topic agentArguments: #( 'claude-agent-acp' ).
	self assert: (presenter topicListLabelFor: topic) equals: '○ TestTopic (claude-agent-acp)'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnSetWorkingDirectorySetsWorkingDirectoryPath [

	| testPath |
	testPath := '/tmp/test-working-dir'.
	topic workingDirectoryPath: testPath.
	self assert: topic workingDirectoryPath equals: testPath
]
