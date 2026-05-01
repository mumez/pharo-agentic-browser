Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageItems',
		'messageToPresenter',
		'listPresenter',
		'scrollPresenter'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messageItems := OrderedCollection new.
	messageToPresenter := IdentityDictionary new.
	listPresenter := self newPresenter.
	listPresenter layout: SpBoxLayout newTopToBottom.
	scrollPresenter := self instantiate: SpScrollPresenter.
	scrollPresenter presenter: listPresenter
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: scrollPresenter;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> addOrUpdateMessage: anAbMessage [
	"Add a new message presenter or update an existing one.
	 AbTopic fires AbMessageAdded for both new messages and streamed chunks
	 (chunk appends reuse the same AbMessage object)."

	(messageToPresenter includesKey: anAbMessage)
		ifTrue: [ (messageToPresenter at: anAbMessage) updateContent ]
		ifFalse: [
			| mp |
			mp := self instantiate: AbMessagePresenter.
			mp message: anAbMessage.
			messageItems add: mp.
			messageToPresenter at: anAbMessage put: mp.
			self rebuildListLayout.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch or status refresh)."

	messageItems := OrderedCollection new.
	messageToPresenter := IdentityDictionary new.
	aCollection do: [ :m |
		| mp |
		mp := self instantiate: AbMessagePresenter.
		mp message: m.
		messageItems add: mp.
		messageToPresenter at: m put: mp ].
	self rebuildListLayout.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh text content of all existing presenters without changing scroll position.
	 Used when message state changes (e.g. approval resolved) affect display text."

	messageItems do: [ :mp | mp updateContent ]
]

{ #category : 'private' }
AbMessagesPresenter >> rebuildListLayout [

	| layout |
	layout := SpBoxLayout newTopToBottom.
	messageItems do: [ :mp | layout add: mp withConstraints: [ :c | c height: 50 ] ].
	listPresenter layout: layout
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [

	self defer: [
		scrollPresenter adapter ifNotNil: [ :a | a widget scrollToBottom ] ]
]

{ #category : 'testing' }
AbMessagesPresenter >> messageCount [

	^ messageItems size
]

{ #category : 'testing' }
AbMessagesPresenter >> messagePresenters [

	^ messageItems copy
]
