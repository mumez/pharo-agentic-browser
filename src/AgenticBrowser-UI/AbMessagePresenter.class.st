Class {
	#name : 'AbMessagePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'message',
		'senderLabel',
		'contentText'
	],
	#classVars : [
		'SenderColors'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagePresenter class >> initialize [

	| theme |
	theme := Smalltalk ui theme.
	SenderColors := Dictionary new.
	SenderColors at: #human put: theme textColor.
	SenderColors at: #ai put: theme lightSelectionColor.
	SenderColors at: #default put: theme ghostTextColor
]

{ #category : 'colors' }
AbMessagePresenter class >> senderColors [

	^ SenderColors
]

{ #category : 'colors' }
AbMessagePresenter class >> senderColorFor: aSender [

	^ SenderColors at: aSender ifAbsent: [ SenderColors at: #default ]
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

	self message sender = #human ifTrue: [ ^ 'You' ].
	self message sender = #ai ifTrue: [
		self message isThink ifTrue: [ ^ 'AI(think)' ].
		self message isApprovalRequest ifTrue: [ ^ 'AI(⏸)' ].
		^ 'AI' ].
	^ 'System'
]

{ #category : 'private' }
AbMessagePresenter >> senderColor [

	^ self class senderColorFor: self message sender
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
