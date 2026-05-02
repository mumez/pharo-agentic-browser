Class {
	#name : 'AbMessagePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'message',
		'senderLabel',
		'contentText'
	],
	#classVars : [
		'SenderLabelColors'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagePresenter class >> initialize [

	| theme |
	theme := Smalltalk ui theme.
	SenderLabelColors := Dictionary new.
	SenderLabelColors at: 'You' put: theme textColor.
	SenderLabelColors at: 'AI' put: theme lightSelectionColor.
	SenderLabelColors at: 'AI(think)' put: Color gray.
	SenderLabelColors at: 'System' put: theme ghostTextColor.
	SenderLabelColors at: 'default' put: theme ghostTextColor
]

{ #category : 'colors' }
AbMessagePresenter class >> senderColors [

	^ SenderLabelColors
]

{ #category : 'colors' }
AbMessagePresenter class >> senderLabelFor: anAbMessage [

	anAbMessage sender = #human ifTrue: [ ^ 'You' ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ 'AI(think)' ].
		^ 'AI' ].
	^ 'System'
]

{ #category : 'colors' }
AbMessagePresenter class >> senderLabelColorFor: anAbMessage [

	| name |
	name := self senderLabelFor: anAbMessage.
	^ SenderLabelColors at: name ifAbsent: [ SenderLabelColors at: 'default' ]
]

{ #category : 'initialization' }
AbMessagePresenter >> initializePresenters [

	senderLabel := self newLabel.
	senderLabel label: ''.

	contentText := self newText.
	contentText beNotEditable
]

{ #category : 'layout' }
AbMessagePresenter >> defaultLayout [

	^ SpBoxLayout newLeftToRight
		  spacing: 4;
		  add: self senderLabel withConstraints: [ :c | c width: 70 ];
		  add: self contentText;
		  yourself
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
	self senderLabel label: (Text
			 string: self senderDisplayName
			 attribute: (TextColor color: self senderColor)).
	self contentText text: anAbMessage text
]

{ #category : 'rendering' }
AbMessagePresenter >> updateContent [

	self contentText text: self message text
]

{ #category : 'accessing' }
AbMessagePresenter >> senderLabel [

	^ senderLabel
]

{ #category : 'accessing' }
AbMessagePresenter >> contentText [

	^ contentText
]

{ #category : 'private' }
AbMessagePresenter >> senderDisplayName [

	^ self class senderLabelFor: self message
]

{ #category : 'private' }
AbMessagePresenter >> senderColor [

	^ self class senderLabelColorFor: self message
]

{ #category : 'testing' }
AbMessagePresenter >> senderLabelText [
	"Return as String because label may be a richtext Text object."

	^ self senderLabel label asString
]

{ #category : 'testing' }
AbMessagePresenter >> contentTextString [

	^ self contentText text
]
