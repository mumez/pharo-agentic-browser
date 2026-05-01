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
AbMessagesPresenter >> initialize [

	super initialize.
	messages := OrderedCollection new
]

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messageList := self newList.
	messageList display: [ :msg | self richTextFor: msg ]
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: self messageList;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> addOrUpdateMessage: anAbMessage [
	"Add a new message or refresh an existing one (e.g. AI streaming chunk).
	 AbTopic fires AbMessageAdded for both cases using object identity."

	(messages includes: anAbMessage)
		ifTrue: [ self messageList refresh ]
		ifFalse: [
			messages add: anAbMessage.
			self messageList items: messages.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	self messages: aCollection asOrderedCollection.
	self messageList items: messages.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self messageList refresh
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages [

	^ messages copy
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages: aCollection [

	messages := aCollection
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageList [

	^ messageList
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ messages size
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	messages ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	self messageList selectIndex: messages size.
	self messageList unselectAll
]

{ #category : 'private' }
AbMessagesPresenter >> richTextFor: anAbMessage [
	"Build a richtext Text with the sender label colored and message text appended."

	| senderPart senderLen fullStr richText |
	senderPart := self senderLabelFor: anAbMessage.
	senderLen := senderPart size.
	fullStr := senderPart , anAbMessage text.
	richText := fullStr asText.
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

	^ AbMessagePresenter senderColorFor: aSender
]
