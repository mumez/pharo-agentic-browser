Class {
	#name : 'AbScreenshotParserTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'tests' }
AbScreenshotParserTest >> testParseNone [

	| result |
	result := AbScreenshotParser parseFrom: 'hello world'.
	self assert: result isEmpty
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseSingle [

	| result |
	result := AbScreenshotParser parseFrom: 'look at @sc-20260527-001.png please'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseMultiple [

	| result |
	result := AbScreenshotParser parseFrom: '@sc-20260527-001.png and @sc-20260527-002.png'.
	self assert: result size equals: 2.
	self assert: result first name equals: 'sc-20260527-001'.
	self assert: result last name equals: 'sc-20260527-002'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseIgnoresOtherMentions [

	| result |
	result := AbScreenshotParser parseFrom: '@SomeClass and @sc-20260527-001.png'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseAtEndOfString [

	| result |
	result := AbScreenshotParser parseFrom: 'see @sc-20260527-001.png'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseDuplicateMentionDeduplicates [

	| result |
	result := AbScreenshotParser parseFrom: '@sc-20260527-001.png @sc-20260527-001.png'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]

{ #category : 'tests' }
AbScreenshotParserTest >> testParseMentionFollowedByPunctuation [

	| result |
	result := AbScreenshotParser parseFrom: '(see @sc-20260527-001.png) and done'.
	self assert: result size equals: 1.
	self assert: result first name equals: 'sc-20260527-001'
]
