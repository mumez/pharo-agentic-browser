Class {
	#name : 'AbCodeMentionParserTest',
	#superclass : 'TestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbCodeMentionParserTest >> testClassMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo'.
	self assert: mention className equals: 'Foo'.
	self assert: mention isClassMention.
	self deny: mention isMethodMention.
	self deny: mention isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testClassSideMethodMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo' methodName: 'new' isClassSide: true.
	self assert: mention isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testIgnoresLowercaseMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@notAClass hello'.
	self assert: mentions isEmpty
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testMethodMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo' methodName: 'bar' isClassSide: false.
	self assert: mention className equals: 'Foo'.
	self assert: mention methodName equals: 'bar'.
	self deny: mention isClassMention.
	self assert: mention isMethodMention.
	self deny: mention isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'Check @OrderedCollection please'.
	self assert: mentions size equals: 1.
	self assert: mentions first className equals: 'OrderedCollection'.
	self assert: mentions first isClassMention
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassMentionAtEndOfString [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'look at @OrderedCollection'.
	self assert: mentions size equals: 1.
	self assert: mentions first isClassMention
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassSideMethodMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection class >> new'.
	self assert: mentions first isClassSide.
	self assert: mentions first methodName equals: 'new'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesClassSideMethodWithHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection class >> #new'.
	self assert: mentions first isClassSide.
	self assert: mentions first methodName equals: 'new'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesEmptyString [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: ''.
	self assert: mentions isEmpty
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesInstanceMethodMention [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: 'See @OrderedCollection >> add:'.
	self assert: mentions size equals: 1.
	self assert: mentions first className equals: 'OrderedCollection'.
	self assert: mentions first methodName equals: 'add:'.
	self deny: mentions first isClassSide
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesKeywordSelectorWithHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> #at:put:'.
	self assert: mentions first methodName equals: 'at:put:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesKeywordSelectorWithoutHash [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> at:put:'.
	self assert: mentions first methodName equals: 'at:put:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesMethodMentionWithHashPrefix [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection >> #add:'.
	self assert: mentions first methodName equals: 'add:'
]

{ #category : 'tests' }
AbCodeMentionParserTest >> testParsesMultipleMentions [

	| mentions |
	mentions := AbCodeMentionParser parseFrom: '@OrderedCollection and @Dictionary >> at:'.
	self assert: mentions size equals: 2.
	self assert: (mentions collect: #className) asArray equals: #('OrderedCollection' 'Dictionary')
]
