Class {
	#name : 'AbCodeMentionEmbedderTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources size equals: 1.
	self assert: resources first key
		equals: 'http://localhost:8086/get-class-source?class_name=OrderedCollection'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassResourceTonelContainsClassName [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first value includesSubstring: 'OrderedCollection')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first key
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=add:&is_class_method=false'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testClassSideMethodResourceHasCorrectUrl [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'new' isClassSide: true.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources first key
		equals: 'http://localhost:8086/get-method-source?class_name=OrderedCollection&method_name=new&is_class_method=true'
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testMethodResourceTonelContainsSelector [

	| mention resources |
	mention := AbCodeMention className: 'OrderedCollection' methodName: 'add:' isClassSide: false.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: (resources first value includesSubstring: 'add:')
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testUnknownClassIsSkipped [

	| mention resources |
	mention := AbCodeMention className: 'NonExistentClass99999'.
	resources := AbCodeMentionEmbedder resourcesFor: { mention }.
	self assert: resources isEmpty
]

{ #category : 'tests' }
AbCodeMentionEmbedderTest >> testEmptyMentionsReturnsEmptyCollection [

	| resources |
	resources := AbCodeMentionEmbedder resourcesFor: #().
	self assert: resources isEmpty
]
