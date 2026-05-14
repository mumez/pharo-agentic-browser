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
AbCodeMentionParser class >> readIdentifierFrom: stream [

	^ self readTokenFrom: stream accepting: [ :ch | ch isLetter or: [ ch isDigit ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> readSelectorFrom: stream [

	^ self readTokenFrom: stream accepting: [ :ch | ch isLetter or: [ ch isDigit or: [ ch = $: ] ] ]
]

{ #category : 'private' }
AbCodeMentionParser class >> readTokenFrom: stream accepting: aTestBlock [

	^ String streamContents: [ :out |
		[ stream atEnd not and: [ aTestBlock value: stream peek ] ]
			whileTrue: [ out nextPut: stream next ] ]
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
	stream skipSeparators.

	isClassSide := self trySkip: 'class' from: stream.
	isClassSide ifTrue: [ stream skipSeparators ].

	(self trySkip: '>>' from: stream) ifFalse: [
		stream position: savedPos.
		^ AbCodeMention className: className ].

	stream skipSeparators.
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
