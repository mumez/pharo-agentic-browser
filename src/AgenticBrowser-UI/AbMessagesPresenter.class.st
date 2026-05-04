Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageList',
		'messages'
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
		  add: self messageList;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> addOrUpdateMessage: anAbMessage [
	"Add a new message or refresh an existing one (e.g. AI streaming chunk).
	 AbTopic fires AbMessageAdded for both cases using object identity."

	(messages includes: anAbMessage)
		ifFalse: [ messages add: anAbMessage ].
	self messageList items: messages asArray.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	messages := aCollection asOrderedCollection.
	self messageList items: messages asArray.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self messageList items: messages asArray
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages [

	^ messages
]

{ #category : 'accessing' }
AbMessagesPresenter >> messagePresenters [

	^ #()
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageList [

	^ messageList
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ messages size
]

{ #category : 'rendering' }
AbMessagesPresenter >> richTextFor: anAbMessage [

	^ AbMessageRichTextBuilder new richTextFor: anAbMessage
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	messages ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	self messageList isBuilt ifFalse: [ ^ self ].
	self messageList adapter widget scrollToIndex: messages size
]

{ #category : 'events' }
AbMessagesPresenter >> windowResized: newSize [

	"newList + rich text display does not require per-item resize forwarding."
]
