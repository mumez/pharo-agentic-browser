Class {
	#name : 'AbCodeMentionEmbedderTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources size equals: 1.
	self assert: resources first uri
		equals: 'http://localhost:8086/get-class-source?class_name=OrderedCollection'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceTonelContainsClassName [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first text includesSubstring: 'OrderedCollection')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassSideMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'new' isClassSide: true.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first uri
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=new&is_class_method=true'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testEmptyMentionsReturnsEmptyCollection [

	| resources |
	resources := AbCodeMentionEmbedder resourcesFor: #().
	self assert: resources isEmpty
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first uri
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=add:&is_class_method=false'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceTonelContainsSelector [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first text includesSubstring: 'add:')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testResourcesForReturnsAbCodeMentionResources [

	| mentions resources |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: mentions.
	self assert: resources size equals: 1.
	self assert: (resources first isKindOf: AbCodeMentionResource)
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testUnknownClassIsSkipped [

	| mention resources |
	mention := AbCodeMention className: 'NonExistentClass99999'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources isEmpty
]
