Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
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

	| existing |
	existing := self messagePresenters
		detect: [ :p | p message == anAbMessage ]
		ifNone: [ nil ].
	existing
		ifNotNil: [ existing updateContent ]
		ifNil: [
			| presenter |
			presenter := self instantiate: AbMessagePresenter.
			presenter updateMessage: anAbMessage.
			self messageList addPresenter: presenter.
			self scrollToBottom ]
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	self messageList items: aCollection.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self messagePresenters do: [ :p | p updateContent ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages [

	^ self messagePresenters collect: [ :e | e message ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messagePresenters [

	^ self messageList model
		ifNil: [ #() ]
		ifNotNil: [ :m | m collection ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageList [

	^ messageList
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ self messagePresenters size
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
	self messageList adapter widget scrollToIndex: self messagePresenters size
]
