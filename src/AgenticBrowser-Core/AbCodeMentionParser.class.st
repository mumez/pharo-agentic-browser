Class {
	#name : 'AbCodeMentionParser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'parsing' }
AbCodeMentionParser class >> parseFrom: aString [

	| mentions stream |
	mentions := OrderedCollection new.
	stream := ReadStream on: aString.
	[ stream atEnd ] whileFalse: [
		stream next = $@ ifTrue: [
			(self tryParseMentionFrom: stream)
				ifNotNil: [ :m | mentions add: m ] ] ].
	^ mentions
]

{ #category : 'private' }
AbCodeMentionParser class >> tryParseMentionFrom: stream [

	| className |
	className := self readIdentifierFrom: stream.
	(className notEmpty and: [ className first isUppercase ])
		ifFalse: [ ^ nil ].
	^ self tryParseRestFrom: stream forClass: className
]

{ #category : 'private' }
AbCodeMentionParser class >> tryParseRestFrom: stream forClass: className [

	| savedPos isClassSide methodName |
	savedPos := stream position.
	self skipSpacesFrom: stream.

	isClassSide := self trySkip: 'class' from: stream.
	isClassSide ifTrue: [ self skipSpacesFrom: stream ].

	(self trySkip: '>>' from: stream) ifFalse: [
		stream position: savedPos.
		^ AbCodeMention className: className ].

	self skipSpacesFrom: stream.
	stream peekFor: $#.
	methodName := self readSelectorFrom: stream.
	methodName ifEmpty: [ ^ AbCodeMention className: className ].
	^ AbCodeMention className: className methodName: methodName isClassSide: isClassSide
]

{ #category : 'private' }
AbCodeMentionParser class >> trySkip: aString from: stream [

	| saved |
	saved := stream position.
	aString do: [ :ch |
		(stream atEnd or: [ stream peek ~= ch ]) ifTrue: [
			stream position: saved.
			^ false ].
		stream next ].
	^ true
]

{ #category : 'private' }
AbCodeMentionParser class >> readIdentifierFrom: stream [

	^ String streamContents: [ :out |
		[ stream atEnd not
			and: [ stream peek isLetter or: [ stream peek isDigit ] ] ]
			whileTrue: [ out nextPut: stream next ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> readSelectorFrom: stream [

	^ String streamContents: [ :out |
		[ stream atEnd not
			and: [ stream peek isLetter or: [ stream peek isDigit
				or: [ stream peek = $: ] ] ] ]
			whileTrue: [ out nextPut: stream next ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> skipSpacesFrom: stream [

	[ stream atEnd not and: [ stream peek isSeparator ] ]
		whileTrue: [ stream next ]
]
