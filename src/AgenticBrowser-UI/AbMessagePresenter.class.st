Class {
	#name : 'AbMessagePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'message',
		'senderLabel',
		'contentText'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

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
		  add: senderLabel withConstraints: [ :c | c width: 70 ];
		  add: contentText;
		  yourself
]

{ #category : 'accessing' }
AbMessagePresenter >> message: anAbMessage [

	message := anAbMessage.
	senderLabel label: (Text
			 string: self senderDisplayName
			 attribute: (TextColor color: self senderColor)).
	contentText text: anAbMessage text
]

{ #category : 'accessing' }
AbMessagePresenter >> message [

	^ message
]

{ #category : 'rendering' }
AbMessagePresenter >> updateContent [

	contentText text: message text
]

{ #category : 'private' }
AbMessagePresenter >> senderDisplayName [

	message sender = #human ifTrue: [ ^ 'You' ].
	message sender = #ai ifTrue: [
		message isThink ifTrue: [ ^ 'AI(think)' ].
		message isApprovalRequest ifTrue: [ ^ 'AI(⏸)' ].
		^ 'AI' ].
	^ 'System'
]

{ #category : 'private' }
AbMessagePresenter >> senderColor [

	message sender = #human ifTrue: [ ^ Color blue darker ].
	message sender = #ai ifTrue: [ ^ Color green darker ].
	^ Color gray
]

{ #category : 'testing' }
AbMessagePresenter >> senderLabelText [
	"Return as String because label may be a richtext Text object."

	^ senderLabel label asString
]

{ #category : 'testing' }
AbMessagePresenter >> contentTextString [

	^ contentText text
]
