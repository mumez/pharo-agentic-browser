Class {
	#name : 'AbTopicListPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter',
		'topic'
	],
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbTopicListPresenterTest >> setUp [

	presenter := AbTopicListPresenter new.
	topic := AbTopic new title: 'TestTopic'
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testAutoExportPreconditionsForNewTopic [

	"Verifies the preconditions for the auto-export path in onPackagePrefixSet:.
	 A freshly-created topic with a matching prefix has:
	   - at least one matching package
	   - no existing working directory on disk
	 The actual export (SisServer call) is verified in the integration smoke test."

	topic packagePrefix: 'AgenticBrowser-*'.
	self assert: topic matchingPackageNames notEmpty.
	self deny: topic workingDirectory path exists
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetEmptyPrefixAddsNewProjectMessage [

	topic packagePrefix: ''.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'new project' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testOnPackagePrefixSetNoMatchAddsSystemMessage [

	topic packagePrefix: 'NonExistentXYZ99-*'.
	presenter onPackagePrefixSet: topic.
	self assert: (topic messages anySatisfy: [ :m |
		m sender = #system and: [ m text includesSubstring: 'No packages match' ] ])
]

{ #category : 'tests' }
AbTopicListPresenterTest >> testTopicListLabelForReturnsIconAndTitle [

	self assert: (presenter topicListLabelFor: topic) equals: '○ TestTopic'
]
