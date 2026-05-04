Class {
	#name : 'AbMessagePresenter',
	#superclass : 'Object',
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'colors' }
AbMessagePresenter class >> senderLabelFor: anAbMessage [

	anAbMessage sender = #human ifTrue: [ ^ 'You' ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ 'AI(think)' ].
		^ 'AI' ].
	^ 'System'
]

{ #category : 'rendering' }
AbMessagePresenter >> richTextFor: anAbMessage [

	| senderText senderLen richText |
	senderText := self class senderLabelFor: anAbMessage.
	richText := Microdown asRichText: (self microdownTextFor: anAbMessage).
	senderLen := senderText size.
	senderLen > 0 ifTrue: [
		richText
			addAttribute: (TextColor color: (self senderColorFor: anAbMessage sender))
			from: 1
			to: senderLen ].
	^ richText
]

{ #category : 'rendering' }
AbMessagePresenter >> microdownTextFor: anAbMessage [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: '## ';
			  nextPutAll: (self class senderLabelFor: anAbMessage);
			  cr;
			  cr;
			  nextPutAll: anAbMessage text ]
]

{ #category : 'private' }
AbMessagePresenter >> senderColorFor: aSenderSymbol [

	aSenderSymbol = #human ifTrue: [ ^ Smalltalk ui theme textColor ].
	aSenderSymbol = #ai ifTrue: [ ^ Smalltalk ui theme lightSelectionColor ].
	^ Smalltalk ui theme ghostTextColor
]