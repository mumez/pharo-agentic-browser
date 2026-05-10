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
AbCodeMentionParserTest >> testClassSideMethodMentionCreation [

	| mention |
	mention := AbCodeMention className: 'Foo' methodName: 'new' isClassSide: true.
	self assert: mention isClassSide
]
