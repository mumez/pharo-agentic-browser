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

	| senderLen richText |
	richText := (self buildStringFor: anAbMessage) asText.
	senderLen := (self class senderLabelFor: anAbMessage) size + 1.
	self applySenderAttributesTo: richText senderLen: senderLen message: anAbMessage.
	anAbMessage isThink ifTrue: [
		self applyThinkBodyAttributesTo: richText bodyStart: senderLen + 3 ].
	^ richText
]

{ #category : 'private' }
AbMessageRichTextBuilder >> buildStringFor: anAbMessage [

	| body |
	body := anAbMessage text ifNil: [ '' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: (self class senderLabelFor: anAbMessage);
			  nextPutAll: ':';
			  cr;
			  cr;
			  nextPutAll: body ]
]

{ #category : 'private' }
AbMessageRichTextBuilder >> applySenderAttributesTo: richText senderLen: senderLen message: anAbMessage [

	richText
		addAttribute: (TextColor color: (self senderColorFor: anAbMessage))
		from: 1
		to: senderLen.
	richText
		addAttribute: TextEmphasis bold
		from: 1
		to: senderLen
]

{ #category : 'private' }
AbMessageRichTextBuilder >> applyThinkBodyAttributesTo: richText bodyStart: bodyStart [

	bodyStart > richText size ifTrue: [ ^ self ].
	richText
		addAttribute: (TextColor color: Smalltalk ui theme ghostTextColor)
		from: bodyStart
		to: richText size
]

{ #category : 'private' }
AbMessageRichTextBuilder >> senderColorFor: anAbMessage [

	anAbMessage sender = #human ifTrue: [ ^ Smalltalk ui theme textColor ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ Smalltalk ui theme ghostTextColor ].
		^ Smalltalk ui theme warningTextColor ].
	^ Smalltalk ui theme textColor
]
