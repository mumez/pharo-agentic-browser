Class {
	#name : 'AbUiConstantsTest',
	#superclass : 'AbTestCase',
	#category : 'AgenticBrowser-Tests',
	#package : 'AgenticBrowser-Tests'
}

{ #category : 'running' }
AbUiConstantsTest >> setUp [
	super setUp.
	AbUiConstants initialize
]

{ #category : 'tests' }
AbUiConstantsTest >> testCheck [
	self deny: AbUiConstants check isNil.
	self assert: (AbUiConstants check isKindOf: Form)
]

{ #category : 'tests' }
AbUiConstantsTest >> testGreenCircle [
	self deny: AbUiConstants greenCircle isNil.
	self assert: (AbUiConstants greenCircle isKindOf: Form)
]

{ #category : 'tests' }
AbUiConstantsTest >> testIconNamedKnownSymbol [
	self assert: ((AbUiConstants iconNamed: #check) isKindOf: Form)
]

{ #category : 'tests' }
AbUiConstantsTest >> testIconNamedUnknownSymbol [
	self assert: (AbUiConstants iconNamed: #zzzzz) isNil
]

{ #category : 'tests' }
AbUiConstantsTest >> testQuestion [
	self deny: AbUiConstants question isNil.
	self assert: (AbUiConstants question isKindOf: Form)
]

{ #category : 'tests' }
AbUiConstantsTest >> testRedCircle [
	self deny: AbUiConstants redCircle isNil.
	self assert: (AbUiConstants redCircle isKindOf: Form)
]

{ #category : 'tests' }
AbUiConstantsTest >> testSparkle [
	self deny: AbUiConstants sparkle isNil.
	self assert: (AbUiConstants sparkle isKindOf: Form)
]
