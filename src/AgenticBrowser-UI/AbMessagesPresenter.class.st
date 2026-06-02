"
I render the conversation history for a topic as a single scrolling rich-text area.

Responsibility:
- I maintain an ordered collection of AbMessage instances and re-render them as combined rich text whenever the collection changes.
- I delegate per-message rendering to AbMessageRichTextBuilder and concatenate the results with CRLF separators.
- I provide a ""Hide think"" checkbox that filters out isThink messages from the visible set without removing them from the internal collection.
- I auto-scroll to the bottom whenever a message is added or updated.

Collaborators:
- AbChatPresenter: It calls #addOrUpdateMessage:, #setMessages:, and #refreshMessages on me.
- AbMessageRichTextBuilder: I call it to convert each AbMessage into formatted rich text.
- MicTextPresenter: My internal read-only text presenter that displays the combined rich text.

Public API and Key Messages:
- #addOrUpdateMessage: - Append a new message or redisplay an existing one (handles streaming chunks via identity check).
- #setMessages: - Full replacement of the message list (used on topic switch).
- #refreshMessages - Re-render all messages without scrolling (used when approval state changes).
- #hideThinkEnabled: - Toggle think-message filtering.

Internal Representation:
- messages - OrderedCollection of all AbMessage instances for the current topic.
- messageTextPresenter - MicTextPresenter rendering the combined rich text.
- hideThinkCheckBox - User control for filtering isThink messages.
"
Class {
	#name : 'AbMessagesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageTextPresenter',
		'messages',
		'hideThinkCheckBox'
	],
	#category : 'AgenticBrowser-UI',
	#package : 'AgenticBrowser-UI'
}

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
AbMessagesPresenter >> combinedRichText [

	| combined isFirst |
	combined := '' asText.
	isFirst := true.
	self visibleMessages do: [ :msg |
		isFirst
			ifFalse: [ combined := combined , String crlf asText , String crlf asText ].
		combined := combined , (self richTextFor: msg).
		isFirst := false ].
	^ combined
]

{ #category : 'layout' }
AbMessagesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: (SpBoxLayout newLeftToRight
				   vAlignCenter;
				   add: self newNullPresenter;
				   add: self hideThinkCheckBox withConstraints: [ :c | c width: 110 ];
				   yourself)
		  withConstraints: [ :c | c height: 26 ];
		  add: self messageTextPresenter;
		  yourself
]

{ #category : 'accessing' }
AbMessagesPresenter >> hideThinkCheckBox [

	^ hideThinkCheckBox
]

{ #category : 'accessing' }
AbMessagesPresenter >> hideThinkEnabled [

	^ hideThinkCheckBox state
]

{ #category : 'accessing' }
AbMessagesPresenter >> hideThinkEnabled: aBoolean [

	hideThinkCheckBox state: aBoolean.
	self refreshCombinedText
]

{ #category : 'initialization' }
AbMessagesPresenter >> initializePresenters [

	super initializePresenters.
	messages := OrderedCollection new.
	messageTextPresenter := self instantiate: MicTextPresenter.
	messageTextPresenter text: '' asText.
	hideThinkCheckBox := self newCheckBox.
	hideThinkCheckBox label: 'Hide think'.
	hideThinkCheckBox whenChangedDo: [ :isChecked |
		self hideThinkEnabled: isChecked ]
]


{ #category : 'accessing' }
AbMessagesPresenter >> messageCount [

	^ self messages size
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageList [

	^ self messageTextPresenter
]

{ #category : 'accessing' }
AbMessagesPresenter >> messagePresenters [

	^ #()
]

{ #category : 'accessing' }
AbMessagesPresenter >> messageTextPresenter [

	^ messageTextPresenter
]

{ #category : 'accessing' }
AbMessagesPresenter >> messages [

	^ messages
]

{ #category : 'private' }
AbMessagesPresenter >> performScrollToBottom [

	self messageTextPresenter isBuilt ifFalse: [ ^ self ].
	self messageTextPresenter adapter widget scrollToEndOfText
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshCombinedText [

	self messageTextPresenter text: self combinedRichText
]

{ #category : 'rendering' }
AbMessagesPresenter >> refreshMessages [
	"Refresh display of all messages without changing scroll position.
	 Used when message state changes (e.g. approval resolved)."

	self refreshCombinedText
]

{ #category : 'rendering' }
AbMessagesPresenter >> richTextFor: anAbMessage [

	^ AbMessageRichTextBuilder new richTextFor: anAbMessage
]

{ #category : 'private' }
AbMessagesPresenter >> scrollToBottom [
	"Scroll the list to show the last (newest) message."

	self messages ifEmpty: [ ^ self ].
	self defer: [ self performScrollToBottom ]
]

{ #category : 'accessing' }
AbMessagesPresenter >> setMessages: aCollection [
	"Full replacement of the message list (e.g. on topic switch)."

	messages := aCollection asOrderedCollection.
	self refreshCombinedText.
	self scrollToBottom
]

{ #category : 'private' }
AbMessagesPresenter >> visibleMessages [

	self hideThinkEnabled ifFalse: [ ^ self messages ].
	^ self messages reject: [ :message | message isThink ]
]
