Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messages',
		'messageList'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messages := OrderedCollection new.
	messageList := self newList.
	messageList display: [ :msg | self richTextFor: msg ]
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: messageList;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> addOrUpdateMessage: anAbMessage [
	"Add a new message or refresh an existing one (e.g. AI streaming chunk).
	 AbTopic fires AbMessageAdded for both cases using object identity."

	(messages includes: anAbMessage)
		ifTrue: [ messageList refresh ]
		ifFalse: [
			messages add: anAbMessage.
			messageList items: messages.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	messages := aCollection asOrderedCollection.
	messageList items: messages.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	messageList refresh
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	messages isEmpty ifTrue: [ ^ self ].
	self defer: [
		messageList selectIndex: messages size.
		messageList unselectAll ]
]

{ #category : 'private' }
AbMessagesPresenter >> richTextFor: anAbMessage [
	"Build a richtext Text with the sender label colored and message text appended."

	| senderPart senderLen fullStr richText |
	senderPart := self senderLabelFor: anAbMessage.
	senderLen := senderPart size.
	fullStr := senderPart , anAbMessage text.
	richText := Text string: fullStr.
	richText
		addAttribute: (TextColor color: (self senderColorFor: anAbMessage sender))
		from: 1
		to: senderLen.
	^ richText
]

{ #category : 'private' }
AbMessagesPresenter >> senderLabelFor: anAbMessage [
	"Fixed-width sender prefix (padded to align the message text column)."

	anAbMessage sender = #human ifTrue: [ ^ 'You      │ ' ].
	anAbMessage sender = #ai ifTrue: [
		anAbMessage isThink ifTrue: [ ^ 'AI(think)│ ' ].
		anAbMessage isApprovalRequest ifTrue: [ ^ 'AI(⏸)   │ ' ].
		^ 'AI       │ ' ].
	^ 'System   │ '
]

{ #category : 'private' }
AbMessagesPresenter >> senderColorFor: aSender [

	aSender = #human ifTrue: [ ^ Color blue darker ].
	aSender = #ai ifTrue: [ ^ Color green darker ].
	^ Color gray
]

{ #category : 'testing' }
AbMessagesPresenter >> messageCount [

	^ messages size
]

{ #category : 'testing' }
AbMessagesPresenter >> messages [

	^ messages copy
]
