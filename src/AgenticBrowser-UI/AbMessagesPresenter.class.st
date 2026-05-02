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
AbMessagesPresenter >> initialize [

	super initialize.
	messages := OrderedCollection new.
	messagePresenters := OrderedCollection new
]

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

	(messages includes: anAbMessage)
		ifTrue: [
			| idx |
			idx := messages indexOf: anAbMessage.
			(messagePresenters at: idx) updateContent ]
		ifFalse: [
			| presenter |
			messages add: anAbMessage.
			presenter := self instantiate: AbMessagePresenter.
			presenter updateMessage: anAbMessage.
			messagePresenters add: presenter.
			messageList presenters: messagePresenters.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	messages := aCollection asOrderedCollection copy.
	messagePresenters := messages collect: [ :m |
		| p |
		p := self instantiate: AbMessagePresenter.
		p updateMessage: m.
		p ].
	messageList presenters: messagePresenters.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	messages doWithIndex: [ :m :i |
		(messagePresenters at: i) updateMessage: m ]
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

	messagePresenters ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	messageList isBuilt ifFalse: [ ^ self ].
	messageList scrollToIndex: messagePresenters size
]
