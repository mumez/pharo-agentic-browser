Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageTextPresenter',
		'messages'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	messages := OrderedCollection new.
	messageTextPresenter := self instantiate: MicTextPresenter.
	messageTextPresenter text: '' asText
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: self messageTextPresenter;
		  yourself
]

{ #category : 'rendering' }
AbMessagesPresenter >> addOrUpdateMessage: anAbMessage [
	"Add a new message or refresh an existing one (e.g. AI streaming chunk).
	 AbTopic fires AbMessageAdded for both cases using object identity."

	(self messages includes: anAbMessage)
		ifFalse: [ self messages add: anAbMessage ].
	self refreshCombinedText.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	messages := aCollection asOrderedCollection.
	self refreshCombinedText.
	self scrollToBottom
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self refreshCombinedText
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

	^ self messageTextPresenter
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ self messages size
]

{ #category : 'rendering' }
AbMessagesPresenter >> richTextFor: anAbMessage [

	^ AbMessageRichTextBuilder new richTextFor: anAbMessage
]

{ #category : 'rendering' }
AbMessagesPresenter >> combinedRichText [

	| combined isFirst |
	combined := '' asText.
	isFirst := true.
	self messages do: [ :msg |
		isFirst
			ifFalse: [ combined := combined , String crlf asText , String crlf asText ].
		combined := combined , (self richTextFor: msg).
		isFirst := false ].
	^ combined
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshCombinedText [

	self messageTextPresenter text: self combinedRichText
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageTextPresenter [

	^ messageTextPresenter
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	self messages ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	self messageTextPresenter isBuilt ifFalse: [ ^ self ].
	self messageTextPresenter adapter widget scrollToEndOfText
]

