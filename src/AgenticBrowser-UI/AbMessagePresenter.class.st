Class {
	#name : 'AbMessagePresenter',
	#superclass : 'MicrodownPresenter',
	#instVars : [
		'message'
	],
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

{ #category : 'accessing' }
AbMessagePresenter >> message: anAbMessage [

	message := anAbMessage
]

{ #category : 'accessing' }
AbMessagePresenter >> message [

	^ message
]

{ #category : 'rendering' }
AbMessagePresenter >> updateMessage: anAbMessage [

	self message: anAbMessage.
	self updateContent
]

{ #category : 'rendering' }
AbMessagePresenter >> updateContent [

	self text: self renderedMicrodownText
]

{ #category : 'private' }
AbMessagePresenter >> senderDisplayName [

	^ self class senderLabelFor: self message
]

{ #category : 'testing' }
AbMessagePresenter >> senderLabelText [

	^ self senderDisplayName
]

{ #category : 'testing' }
AbMessagePresenter >> contentTextString [

	^ self message ifNil: [ '' ] ifNotNil: [ self message text ]
]

{ #category : 'testing' }
AbMessagePresenter >> microdownTextString [

	^ self text
]

{ #category : 'private' }
AbMessagePresenter >> renderedMicrodownText [
	"Use a heading for sender then the message body in a single Microdown document."

	| body |
	body := self message
		        ifNil: [ '' ]
		        ifNotNil: [ self message text ifNil: [ '' ] ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: '## ';
			  nextPutAll: self senderDisplayName;
			  cr;
			  cr;
			  nextPutAll: body ]
]

{ #category : 'events' }
AbMessagePresenter >> windowResized: newSize [

	"MicrodownPresenter handles text layout recalculation."
]