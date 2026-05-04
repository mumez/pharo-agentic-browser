Class {
	#name : 'AbMessageRichTextBuilder',
	#superclass : 'Object',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'colors' }
AbMessageRichTextBuilder class >> senderLabelFor: anAbMessage [

	anAbMessage sender = #human ifTrue: [ ^ 'You' ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ 'AI(think)' ].
		^ 'AI' ].
	^ 'System'
]

{ #category : 'rendering' }
AbMessageRichTextBuilder >> richTextFor: anAbMessage [

	| senderText senderLen body richText |
	senderText := self class senderLabelFor: anAbMessage.
	body := anAbMessage text ifNil: [ '' ].
	richText := String streamContents: [ :stream |
		            stream
			            nextPutAll: senderText;
			            cr;
			            cr;
			            nextPutAll: body ].
	richText := richText asText.
	senderLen := senderText size.
	senderLen > 0 ifTrue: [
		richText
			addAttribute: (TextColor color: (self senderColorFor: anAbMessage sender))
			from: 1
			to: senderLen ].
	^ richText
]

{ #category : 'private' }
AbMessageRichTextBuilder >> senderColorFor: aSenderSymbol [

	aSenderSymbol = #human ifTrue: [ ^ Smalltalk ui theme textColor ].
	aSenderSymbol = #ai ifTrue: [ ^ Smalltalk ui theme lightSelectionColor ].
	^ Smalltalk ui theme ghostTextColor
]
