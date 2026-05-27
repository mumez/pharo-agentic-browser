Class {
	#name : 'AbScreenshotParser',
	#superclass : 'Object',
	#category : 'AgenticBrowser-Core',
	#package : 'AgenticBrowser-Core'
}

{ #category : 'parsing' }
AbScreenshotParser class >> parseFrom: aString [

	| results stream |
	results := OrderedCollection new.
	stream := ReadStream on: aString.
	[ stream atEnd ] whileFalse: [
		stream next = $@ ifTrue: [
			(self tryParseFrom: stream) ifNotNil: [ :att |
				(results noneSatisfy: [ :a | a name = att name ])
					ifTrue: [ results add: att ] ] ] ].
	^ results
]

{ #category : 'private' }
AbScreenshotParser class >> isFilenameChar: aChar [

	^ aChar isLetter or: [ aChar isDigit or: [ aChar = $- or: [ aChar = $. ] ] ]
]

{ #category : 'private' }
AbScreenshotParser class >> tryParseFrom: stream [

	| saved token name |
	saved := stream position.
	token := String streamContents: [ :out |
		[ stream atEnd or: [ (self isFilenameChar: stream peek) not ] ] whileFalse: [
			out nextPut: stream next ] ].
	((token beginsWith: 'sc-') and: [ token endsWith: '.png' ]) ifFalse: [
		stream position: saved.
		^ nil ].
	name := token copyFrom: 1 to: token size - 4.
	^ AbScreenshotAttachment named: name
]
