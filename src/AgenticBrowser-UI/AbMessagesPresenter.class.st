Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messages',
		'messagePresenters',
		'messageList'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messageList := self newComponentList
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

	(self messages includes: anAbMessage)
		ifTrue: [
			| idx |
			idx := self messages indexOf: anAbMessage.
			(self messagePresenters at: idx) updateContent ]
		ifFalse: [
			| presenter |
			self messages add: anAbMessage.
			presenter := self instantiate: AbMessagePresenter.
			presenter updateMessage: anAbMessage.
			self messagePresenters add: presenter.
			self messageList presenters: self messagePresenters.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	self messages: aCollection asOrderedCollection copy.
	self messagePresenters: (self messages collect: [ :m |
		| p |
		p := self instantiate: AbMessagePresenter.
		p updateMessage: m.
		p ]).
	self messageList presenters: self messagePresenters.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self messages doWithIndex: [ :m :i |
		(self messagePresenters at: i) updateMessage: m ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages [

	^ messages ifNil: [ messages := OrderedCollection new ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages: aCollection [

	messages := aCollection
]

{ #category : 'accessing' }
AbMessagesPresenter >> messagePresenters [

	^ messagePresenters ifNil: [ messagePresenters := OrderedCollection new ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messagePresenters: aCollection [

	messagePresenters := aCollection
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageList [

	^ messageList
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ self messages size
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	self messagePresenters ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	self messageList isBuilt ifFalse: [ ^ self ].
	self messageList scrollToIndex: self messagePresenters size
]
