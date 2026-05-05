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
			            nextPutAll: ':';
			            cr;
			            cr;
			            nextPutAll: body ].
	richText := richText asText.
	senderLen := senderText size + 1.
	senderLen > 0 ifTrue: [
		richText
			addAttribute: (TextColor color: (self senderColorFor: anAbMessage))
			from: 1
			to: senderLen.
		richText
			addAttribute: TextEmphasis bold
			from: 1
			to: senderLen ].
	(anAbMessage isThink and: [ body notEmpty ]) ifTrue: [
		| bodyStart |
		bodyStart := senderLen + 3.
		richText
			addAttribute: (TextColor color: Smalltalk ui theme ghostTextColor)
			from: bodyStart
			to: richText size ].
	^ richText
]

{ #category : 'private' }
AbMessageRichTextBuilder >> senderColorFor: anAbMessage [

	anAbMessage sender = #human ifTrue: [ ^ Smalltalk ui theme textColor ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ Smalltalk ui theme ghostTextColor ].
		^ Smalltalk ui theme warningTextColor ].
	^ Smalltalk ui theme textColor
]
